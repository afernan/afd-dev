function incbuild() {
  var incr = (eval(increment) != undefined) ? increment : 1;
  if (incr == 0) {
    WScript.Echo("Skipping BUILDNUMBER increment.\n");
    CWSys.exit(0);
  }
  var file = "src/buildnum.h";
  var buildNumText = "#define BUILDNUMBER ";
  var s = CWSys.readStringFromFile(file);
  var n = eval(s.substring(buildNumText.length)) + 1;

  if (n == Math.NaN) {
    WScript.Echo("Error incrementing BUILDNUMBER, result is NaN.\n");
    CWSys.exit(1);
  }
  WScript.Echo("Incrementing BUILDNUMBER.\n");
  CWSys.writeStringToFile(file, buildNumText + n + '\n');
}
