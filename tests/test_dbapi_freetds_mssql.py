import cyanodbc
import dbapi20


class CyanodbcDBApiTest(dbapi20.DatabaseAPI20Test):
    driver = cyanodbc
    connect_args = ("Driver={FreeTDS};Server=127.0.0.1;Port=1433;TDS_Version=7.3;UID=sa;PWD=Password12!;Database=tempdb;", )
    ""

    # nanodbc fetches all long columns using exact
    # size specification - there is no need for user
    # interaction here
    def test_setoutputsize(self):
        pass

    def test_nextset(self):
        pass # for sqlite no nextset()
