"""
Binary to N88-BASIC(86) file wrapper
"""

from io import StringIO
import sys

# Max line length to produce. On a 80 columns screen, 17 bytes (printed as 3 digits + one
# comma) leaves only 2 characters unused.
LINE_LENGTH = 17

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} source_file destination_file")

    with open(sys.argv[1], "rb") as f:
        program_data = f.read()


    doc = StringIO()
    program_len = len(program_data)

    doc.write(f"10 FOR I=0 TO {program_len-1}\r\n")
    doc.write("20 READ C\r\n")
    doc.write("30 POKE &HF000+I,C\r\n")
    doc.write("40 NEXT I\r\n")
    doc.write("50 DEF USR0=&HF000\r\n")
    doc.write("60 I=USR0(0)\r\n")

    offset = 0
    line_index = 70

    while True:
        byte_slice = program_data[offset:offset+LINE_LENGTH]
        if not byte_slice:
            break

        slice_generator = (str(x) for x in byte_slice)
        doc.write(f"{line_index} DATA {','.join(slice_generator)}\r\n")

        line_index += 1
        offset += LINE_LENGTH

    # Write a "direct statement" at the end of the file, since we don't know how to
    # properly terminate the file... yet.
    doc.write("END\r\n")

    with open(sys.argv[2], "w") as f:
        f.write(doc.getvalue())


if __name__ == "__main__":
    main()
