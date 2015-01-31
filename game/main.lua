-- Change this variable to select a test.
local exampleName;
exampleName = "basic";
exampleName = "intermediate";
exampleName = "guy";

require("examples." .. exampleName .. "." .. exampleName);