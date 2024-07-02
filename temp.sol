For the following solidity code constructor function
```
constructor()
        ERC721("Sword", "SW")
        Ownable(0xB1293a8BFf9323AaD0419e46dd9846cC7363d44B) //@auditV2 :is cciphandler contract is owner of rpg contract??seems incorrect
    {
        baseStat.stat1 = 10;
        baseStat.stat2 = 20;
        baseStat.specialType = 30;
        baseStat.specialPoints = 40;
        statLabels = ["l1", "l2"];
        itemType = "weapon";
        svgColors = ["#f2f2f2", "#2f2f2f", "#dedede"];
        colorRanges = [0, 10, 20, 30];
        _ccipHandler = 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a; //made it temporary hardcoded with respect to cciplocal simulator sender router address

        //@auditV2...if you deploying the handler first ..then how predetermining of this address is possible  //_cciphandler = sender ka ya receiver ka? //advisable do not hardcode the
        //_ccipHandler address pass it dynmically via construcot..also include once function to set the ccip handler later on
        mintPrice = 10000000000000000;
        _parentChainId = 1;
    }


```

And for following its test function for statLaels:

```
 function testConstructor() public {

        vm.selectFork(sepoliaFork);
           // Test statLabels
            (string memory label1, string memory label2) = rpg.statLabels();
            assertEq(label1, "l1");
            assertEq(label2, "l2");

```
I am getting following error:

``
 Wrong argument count for function call: 0 arguments given but expected 1.
   --> test/gameXForked.t.sol:103:60:
    |
103 |             (string memory label1, string memory label2) = rpg.statLabels();
    |                                                            ^^^^^^^^^^^^^^^^

Error (7364): Different number of components on the left hand side (2) than on the right hand side (1).
   --> test/gameXForked.t.sol:103:13:
    |
103 |             (string memory label1, string memory label2) = rpg.statLabels();
``


function testConstructor() public {
    vm.selectFork(sepoliaFork);
    // Assuming statLabels() takes an index and returns a single string label
    assertEq(rpg.statLabels(0), "l1");
    assertEq(rpg.statLabels(1), "l2");

    // Test itemType
    assertEq(rpg.itemType(), "weapon");

    // Test mintPrice
    assertEq(rpg.mintPrice(), 10000000000000000);
}