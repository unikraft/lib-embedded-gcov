#!/usr/bin/python3
import os
import sys
import argparse

GCOV_END = "Gcov End"

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--filename", required=True, type=str, help="The filename of the dump file")
    parser.add_argument("--output", required=True, type=str, help="The path of the output folder")
    args = parser.parse_args()

    return args

def main():
    args = parse_args()
    dump_filename = args.filename
    relative_path = args.output

    # check if output folder exists otherwise create it
    os.makedirs(relative_path, exist_ok=True)

    with open(dump_filename, "rb") as f:
        # read the whole file
        data = f.read()
        while True:
            # get the index of the first /x00
            index = data.index(b"\x00")
            # get the string before the /x00
            string = data[:index]
            filename = string.decode("utf-8")
            if not filename:
                print ("Empty string")

            if filename == GCOV_END:
                break

            # extract the last part of the path
            filename = filename.split("/")[-1]

            # get over the string
            data = data[index+1:]
            # read 4 bytes that represent the size of the file
            size = int.from_bytes(data[:4], byteorder="big")
            filedata = data[4:4+size]
            # create a file with the name of the string and write the data

            with open(os.path.join(relative_path, filename), "wb") as f:
                    f.write(filedata)

            # get over the data
            data = data[4 + size:]

if __name__ == "__main__":
    main()
