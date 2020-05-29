cdef class Connection:
    cdef nanodbc.connection c_cnxn
    cdef nanodbc.statement  c_stmt
    cdef unique_ptr[nanodbc.transaction] c_trxn_ptr
    cdef unique_ptr[nanodbc.catalog] c_cat_ptr
    cdef unique_ptr[nanodbc.tables] c_tbl_ptr
    cdef unique_ptr[nanodbc.columns] c_col_ptr

    def __cinit__(self):
        self.c_cnxn = nanodbc.connection()
        self.c_cat_ptr.reset(new nanodbc.catalog(self.c_cnxn))
        self.c_trxn_ptr.reset(new nanodbc.transaction(self.c_cnxn))

    def _connect(self, dsn, username=None, password=None, long timeout=0):
        if username and password:
            self.c_cnxn.connect(dsn.encode(),username.encode(), password.encode(), timeout)
        else:
            self.c_cnxn.connect(dsn.encode(), timeout)
        self.c_stmt = nanodbc.statement(self.c_cnxn)

    def find_tables(self, catalog, schema, table, type):
        out = []
        try:
            self.c_tbl_ptr.reset(new nanodbc.tables(
                deref(self.c_cat_ptr).find_tables(
                    table = table.encode(),
                    type = type.encode(),
                    schema = schema.encode(),
                    catalog = catalog.encode()
                )
            ))
            Row = namedtuple(
                'Row',
                ["catalog", "schema", "name", "type"],
                rename=True)
            while deref(self.c_tbl_ptr).next():
                out.append(Row(*[
                deref(self.c_tbl_ptr).table_catalog().decode(),
                deref(self.c_tbl_ptr).table_schema().decode(),
                deref(self.c_tbl_ptr).table_name().decode(),
                deref(self.c_tbl_ptr).table_type().decode()
                ]))
            return out
        except RuntimeError as e:
            raise DatabaseError("Error in find_tables: " + str(e)) from e

    def find_columns(self, catalog, schema, table, column):
        out = []
        self.c_col_ptr.reset(new nanodbc.columns(
            deref(self.c_cat_ptr).find_columns(
                column = column.encode(),
                table = table.encode(),
                schema = schema.encode(),
                catalog = catalog.encode()
            )
        ))
        Row = namedtuple(
            'Row',
            ["catalog", "schema", "table", "column", "data_type", "type_name", "column_size", "buffer_length", "decimal_digits", "numeric_precision_radix", "nullable", "remarks", "default", "sql_data_type", "sql_datetime_subtype", "char_octet_length"],
            rename=True)
        while deref(self.c_col_ptr).next():
            out.append(Row(*[
                deref(self.c_col_ptr).table_catalog().decode(),
                deref(self.c_col_ptr).table_schema().decode(),
                deref(self.c_col_ptr).table_name().decode(),
                deref(self.c_col_ptr).column_name().decode(),
                deref(self.c_col_ptr).data_type(),
                deref(self.c_col_ptr).type_name().decode(),
                deref(self.c_col_ptr).column_size(),
                deref(self.c_col_ptr).buffer_length(),
                deref(self.c_col_ptr).decimal_digits(),
                deref(self.c_col_ptr).numeric_precision_radix(),
                deref(self.c_col_ptr).nullable(),
                deref(self.c_col_ptr).remarks().decode(),
                deref(self.c_col_ptr).column_default().decode(),
                deref(self.c_col_ptr).sql_data_type(),
                deref(self.c_col_ptr).sql_datetime_subtype(),
                deref(self.c_col_ptr).char_octet_length()
            ]))
        return out

    def list_catalogs(self):
        try:
            res = deref(self.c_cat_ptr).list_catalogs()
        except RuntimeError as e:
            raise DatabaseError("Error in list_catalogs: " + str(e)) from e
        return [a.decode() for a in res]

    def list_schemas(self):
        try:
            res = deref(self.c_cat_ptr).list_schemas()
        except RuntimeError as e:
            raise DatabaseError("Error in list_schemas: " + str(e)) from e
        return [a.decode() for a in res]

    def commit(self):
        if self.c_cnxn.connected():
            deref(self.c_trxn_ptr).commit()
        else:
            raise DatabaseError("Connection inactive")
    
    def rollback(self):
        if self.c_cnxn.connected():
            deref(self.c_trxn_ptr).rollback()
        else:
            raise DatabaseError("Connection inactive")
        

    def get_info(self, short info_type):
        return self.c_cnxn.get_info[string](info_type).decode()


    @property    
    def Error(self):
        return Error
    @property    
    def Warning(self):
        return Warning
    @property    
    def InterfaceError(self):
        return InterfaceError
    @property    
    def DatabaseError(self):
        return DatabaseError
    @property    
    def InternalError(self):
        return InternalError
    @property    
    def OperationalError(self):
        return OperationalError
    @property    
    def ProgrammingError(self):
        return ProgrammingError
    @property    
    def IntegrityError(self):
        return IntegrityError
    @property    
    def DataError(self):
        return DataError
    @property    
    def NotSupportedError(self):
        return NotSupportedError
    
    def cursor(self):
        return Cursor(self)

    def close(self):
        #try:
            if self.c_cnxn.connected():
                self.c_stmt.close()
                self.c_cnxn.disconnect()
            else:
                raise DatabaseError("Connection inactive")
        
            #log(traceback.format_exc(e), logging.WARNING)
             
            

    # @property
    # def transactions(self):
    
    #     return self.c_cnxn.transactions()

    @property
    def dbms_name(self):
        return self.c_cnxn.dbms_name().decode('UTF-8')
    
    # @property
    # def dbms_version(self):
    #     return self.c_cnxn.dbms_version().decode('UTF-8')

    # @property
    # def driver_name(self):
    #     return self.c_cnxn.driver_name().decode('UTF-8')

    # @property
    # def database_name(self):
    #     return self.c_cnxn.database_name().decode('UTF-8')

    # @property
    # def catalog_name(self):
    #     return self.c_cnxn.catalog_name().decode('UTF-8')

def connect(dsn, username=None, password=None, long timeout=0):
    cnxn = Connection()
    cnxn._connect(dsn, username, password, timeout)
    return cnxn
