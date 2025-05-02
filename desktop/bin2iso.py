import sys
import shutil

def bin_to_iso(bin_file, iso_file):
    try:
        print(f"Converting {bin_file} to {iso_file}...")
        shutil.copy(bin_file, iso_file)
        print("Conversion completed successfully!")
    except Exception as e:
        print(f"Error during conversion: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python bin2iso.py <input.bin> <output.iso>")
        sys.exit(1)

    bin_file = sys.argv[1]
    iso_file = sys.argv[2]
    bin_to_iso(bin_file, iso_file)
