-- Change this variable to select a test.
local exampleName;
exampleName = "basic";
exampleName = "intermediate";
exampleName = "advanced";
exampleName = "guy";

LIBNAME = "lovebone";

require("examples." .. exampleName .. "." .. exampleName);

LIBNAME = nil;