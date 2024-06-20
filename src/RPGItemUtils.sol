// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RPGItemUtils {
    struct StatType { // No change to this stat.
        uint8 stat1;
        uint8 stat2;
        uint8 specialType;
        uint8 specialPoints;
    }

    function generateSVG(
        string memory color,
        string memory stat1,
        string memory stat2,
        string memory powerLvl,
        string memory image,
        string memory name
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:svgjs='http://svgjs.com/svgjs' width='300' height='300' preserveAspectRatio='none' viewBox='0 0 500 500'>",
                    "<rect width='100%' height='100%' fill='",
                    color,
                    "'/>",
                    generateCircle(stat1, "80"),
                    generateCircle(stat2, "180"),
                    generateCircle(powerLvl, "280"),
                    "<image x='100' y='50' width='300' height='300' href='",
                    image,
                    "'/>",
                    "<text x='250' y='420' fill='black' font-size='24' dominant-baseline='middle' text-anchor='middle'>",
                    name,
                    "</text>",
                    "<rect x='0' y='0' width='500' height='500' fill='none' stroke='#000000' stroke-width='5' rx='15' ry='15'/>",
                    "</svg>"
                )
            );
    }

    function generateCircle(string memory value, string memory loc)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<circle cx='50' cy='",
                    loc,
                    "' r='40' fill='#00aaff' stroke='#000000' stroke-width='3' />",
                    "<text x='50' y='",
                    loc,
                    "' fill='black' font-size='24' dominant-baseline='middle' text-anchor='middle'>",
                    value,
                    "</text>"
                )
            );
    }

    function stringEqual(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        return
            bytes32(keccak256(abi.encode(str1))) ==
            bytes32(keccak256(abi.encode(str2)));
    }

    function _generateStatHash(StatType memory _stat)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Calculate the size of the struct in bytes
            let size := mload(_stat)
            // Point to the memory location of the struct
            let ptr := _stat
            // Compute the hash using Keccak256
            hash := keccak256(ptr, size)
        }
        // return
        //   keccak256(
        //     abi.encode(
        //       _stat.stat1,
        //       _stat.stat2,
        //       _stat.specialType,
        //       _stat.specialPoints
        //     )
        //   );
    }
}