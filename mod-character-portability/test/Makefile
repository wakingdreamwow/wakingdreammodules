CXX ?= g++
CXXFLAGS ?= -std=c++17 -O2 -Wall -Wno-unused-function

SRC := ../src/CharacterPortability_Crypto.cpp ../src/CharacterPortability_Codec.cpp
INCLUDES := -I../src -Istubs
LIBS := -lssl -lcrypto -largon2

smoke_test: smoke_test.cpp $(SRC)
	$(CXX) $(CXXFLAGS) $(INCLUDES) smoke_test.cpp $(SRC) $(LIBS) -o smoke_test

.PHONY: run
run: smoke_test
	./smoke_test

.PHONY: clean
clean:
	rm -f smoke_test
