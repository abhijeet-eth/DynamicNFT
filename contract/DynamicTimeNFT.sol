// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract DynamicTimeNFT is ERC721, ERC721URIStorage, KeeperCompatibleInterface, Ownable  {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    enum DayPhase{
        morning,
        noon,
        evening,
        night
    }

    DayPhase public dayPhase;

    uint public /* immutable */ interval; 
    uint public lastTimeStamp;

    uint256 public currentPrice;
    uint256 public latest;
    
    // IPFS URIs for the dynamic nft metadata.

    string[] IpfsUris = [
        "https://gateway.pinata.cloud/ipfs/QmQjX4Y9Re5dNPmm7MqhFbkUTyfRvfigitHLahHsCPUvBn/morning.json",
        "https://gateway.pinata.cloud/ipfs/QmQjX4Y9Re5dNPmm7MqhFbkUTyfRvfigitHLahHsCPUvBn/afternoon.json",
        "https://gateway.pinata.cloud/ipfs/QmQjX4Y9Re5dNPmm7MqhFbkUTyfRvfigitHLahHsCPUvBn/evening.json",
        "https://gateway.pinata.cloud/ipfs/QmQjX4Y9Re5dNPmm7MqhFbkUTyfRvfigitHLahHsCPUvBn/night.json"
    ];


    constructor(uint updateInterval) ERC721("DynamicTime", "DMT") {
        // Set the keeper update interval
        interval = updateInterval; 
        lastTimeStamp = block.timestamp;  //  seconds since unix epoch
    }

    function safeMint(address to) public  {

        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _safeMint(to, tokenId);

        // Default to a bull NFT
        string memory defaultUri = IpfsUris[0];
        _setTokenURI(tokenId, defaultUri);

    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /*performData */) {
         upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;         
            

            if (dayPhase == DayPhase.morning) {
                // morning
                updateAllTokenUris(0);
                dayPhase = DayPhase.noon;

            } else if(dayPhase == DayPhase.noon) {
                // noon
                updateAllTokenUris(1);
                dayPhase = DayPhase.evening;
            }

            else if(dayPhase == DayPhase.evening) {
                // evening
                updateAllTokenUris(2);
                dayPhase = DayPhase.night;
            }

            else if(dayPhase == DayPhase.night) {
                // night
                updateAllTokenUris(3);
                dayPhase = DayPhase.morning;
            }

            // update currentPrice
        } 
            return;
        }


    // Helper Functions
   
    function updateAllTokenUris(uint id) internal {

            for (uint i = 0; i < _tokenIdCounter.current() ; i++) {
                _setTokenURI(i, IpfsUris[id]);
            }
              
    }

    function setDayPhase(DayPhase _day) public onlyOwner {
        dayPhase = _day;
    }
    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
