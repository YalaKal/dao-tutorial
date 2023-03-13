// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * 
 *  Interface for the FakeNFTMarketplace
 *  
 */
interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

/**
 * Minimal interface for CryptoDevsNFT
 */
interface ICryptoDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

// Create a struct named Proposal containing all relevant information
struct Proposal {
  // nftTokenId - the tokenID of the NFT to purchase from the FakeNFTMarketplace
  uint256 nftTokenId;
  // deadline - the UNIX timestamp until which this proposal is active
  uint256 deadline;
  // yayVotes - number of yay votes for this proposal
  uint256 yayVotes;
  // nayVotes - number of nay votes for this proposal
  uint256 nayVotes;
  // executed - Wheter or not this proposal has been executed yet
  bool executed;
  // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating 
  // indicating whether that NFT has already been used to cast a vote or not yet
  mapping(uint256 => bool) voters;
}



contract CryptoDevsDAO is Ownable {

  // Create a mapping of ID to Proposal
  mapping(uint256 => Proposal) public proposals;
  // Number of proposals that have been created
  uint256 public numProposals;

  IFakeNFTMarketplace nftMarketplace;
  ICryptoDevsNFT cryptoDevsNFT;

  constructor (address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
  }

  modifier nftHolderOnly {
    require(cryptoDevsNFT.balanceOf(msg.sender) > 0 ,"Not DAO Member");
    _;
  }

  modifier activeProposalOnly (uint256 proposalIndex) {
    require(
      proposals[proposalIndex].deadline > block.timestamp,
      "Deadline Exceeded"
    );
    _;
  }

  modifier inactiveProposalOnly (uint256 proposalINdex) {
    require(
      proposals[proposalINdex].deadline <=block.timestamp,
      "Deadline not exceeded"
    );
    require(
      proposals[proposalINdex].executed == false,
      "Proposal Already Executed"
    );
    _;
  }

  enum Vote {
    YAY, // =0
    NAY  // =1
  }

  function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
    require(nftMarketplace.available(_nftTokenId), "NFT Not For Sale");
    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;
    proposal.deadline = block.timestamp + 5 minutes;

    numProposals++;
    return numProposals - 1;
  }

  function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex) {
    Proposal storage proposal = proposals[proposalIndex];
    uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
    uint256 numVotes = 0;

    for (uint256 i = 0; i < voterNFTBalance; i++) {
      uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
      if (proposal.voters[tokenId] == false) {
        numVotes++;
        proposal.voters[tokenId] = true;
      }
    }
    require(numVotes > 0, "Already Voted");
    if (vote == Vote.YAY) {
      proposal.yayVotes += numVotes;
    } else {
      proposal.nayVotes += numVotes;
    }
  }

  function executeProposal(uint256 proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
    Proposal storage proposal = proposals[proposalIndex];

    if (proposal.yayVotes > proposal.nayVotes) {
      uint256 nftPrice = nftMarketplace.getPrice();
      require(address(this).balance >= nftPrice, 'Not Enough Funds');
      nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }

    proposal.executed = true;
  }

  function withdrawEther() external onlyOwner {
    uint256 amount = address(this).balance;
    require(amount > 0, 'Nothing to withdraw, contract balance is empty');
    (bool sent, ) = payable(owner()).call{value: amount}("");
    require(sent, 'Failed To Withdraw Ether');
  }

  receive() external payable {}

  fallback() external payable {}



}