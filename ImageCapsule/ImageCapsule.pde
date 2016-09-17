import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.Path;
import java.nio.ByteBuffer;

final int HEADER_LENGTH = 4;
final int INT_SIZE = 8;

PImage src;
PImage encoded;
PImage enc;

void setup()
{
  println("Image Capsule");

  // read in and encode
  println("encoding...");
  src = loadImage("lena.png");
  src.save("data/lena_orig.png");
  byte[] origData = loadBytes("data/cameraman.gif");

  println("Possible Data Length: " + ((src.pixels.length / 8) - HEADER_LENGTH) + " bytes");
  println("Data Length: " + (origData.length) + " bytes");

  encoded = encapsule(src.copy(), origData);
  encoded.save("data/encoded.png");

  // read in and decode
  println("decoding...");
  enc = loadImage("encoded.png");
  byte[] result = decapsule(enc.copy());
  saveBytes("data/decoded.gif", result);
  println("done!");
}

void draw()
{
  background(0);
  text("DONE!", width /2, height / 2);
  
  if(frameCount == 100)
    exit();
}

byte[] decapsule(PImage image)
{
  // read header data
  int headerPixelLength = HEADER_LENGTH * INT_SIZE;
  String buffer = "";
  for (int i = 0; i < headerPixelLength; i++)
  {
    int d = image.pixels[i];
    buffer += ((d & 1) != 0) ? 1 : 0;
  }

  int dataLength = Integer.parseInt(buffer, 2);
  println("Decoded Data Length: " + dataLength + " bytes");

  byte[] data = new byte[dataLength];

  for (int i = 0; i < dataLength; i++)
  {
    buffer = "";
    for (int j = 0; j < 8; j++)
    {
      int d = image.pixels[(i * INT_SIZE) + j + headerPixelLength];
      buffer += ((d & 1) != 0) ? 1 : 0;
    }

    data[i] = (byte)Integer.parseInt(buffer, 2);
  }

  return data;
}

PImage encapsule(PImage image, byte[] data)
{
  // create data with header to block
  byte[] header = intToByteArray(data.length);
  byte[] block = concat(header, data); //<>//

  // go through pixels and set data
  for (int i = 0; i < block.length; i++)
  {
    int d = block[i];

    boolean[] bits = toBinary(d, INT_SIZE);
    for (int j = 0; j < 8; j++)
    {
      // get current bit 
      int index = (i * INT_SIZE) + j;
      boolean b = bits[j];

      if (b)
        image.pixels[index] = makeUnevenByte(image.pixels[index]);
      else
        image.pixels[index] = makeEvenByte(image.pixels[index]);
    }
  }

  println();

  return image;
}

public int makeEvenByte(int number)
{
  if ((number & 1) != 0)
    number--;

  return number;
}

public int makeUnevenByte(int number)
{
  if ((number & 1) == 0)
    number--;

  return number;
}

public static final byte[] intToByteArray(int value) {
  return new byte[] {
    (byte)(value >>> 24), 
    (byte)(value >>> 16), 
    (byte)(value >>> 8), 
    (byte)value};
}

private static boolean[] toBinary(int number, int base) {
  final boolean[] ret = new boolean[base];
  for (int i = 0; i < base; i++) {
    ret[base - 1 - i] = (1 << i & number) != 0;
  }
  return ret;
}