#!/bin/bash -ue

if [[ "$TRAVIS_TAG" =~ ^v.*$ ]]
then
  twine upload --repository-url https://test.pypi.org/legacy/ -u $TEST_PYPI_USERNAME -p $TEST_PYPI_PASSWORD  $TRAVIS_BUILD_DIR/build/src/cython/dist/Cyanodbc*.whl
  twine upload -u $PYPI_USERNAME -p $PYPI_PASSWORD  $TRAVIS_BUILD_DIR/build/src/cython/dist/Cyanodbc*.whl
else
  twine upload --repository-url https://test.pypi.org/legacy/ -u $TEST_PYPI_USERNAME -p $TEST_PYPI_PASSWORD  $TRAVIS_BUILD_DIR/build/src/cython/dist/Cyanodbc*.whl
fi

