#!/bin/bash

bugDataPath=$1
bugID=$2
defects4jHome=$3

java -Xmx1g -cp "patched:target/dependency/*" edu.lu.uni.serval.tbar.main.Main $bugDataPath $bugID $defects4jHome