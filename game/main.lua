-- Change this variable to select a test.
local exampleFile;
exampleFile = "basic";
exampleFile = "guy";

require("examples." .. exampleFile);