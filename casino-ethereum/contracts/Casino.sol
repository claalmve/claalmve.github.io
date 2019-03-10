// May need to change to pragma solidity ^0.5.1;
pragma solidity ^0.5.0;

// import "github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol";

/// @title Contract to bet Ether for a number and win randomly when the number of bets is met.
/// Credit to Merunas Grincalaitis for the framework for this Smart Contract
/// @author Calvin Chen

contract Casino {  //is usingOraclize {
	address owner;

	// The minimum bet a user has to make to participate in the game
	uint public minimumBet = 100 finney; // Equal to 0.1 ether

	// The total amount of Ether bet for this current game
	uint public totalBet;

	// The total number of bets the users have made
	uint public numberOfBets;

	// The maximum amount of bets can be made for each game
	uint public maxAmountOfBets = 10;

	// The max amount of bets that cannot be exceeded to avoid excessive gas consumption
	// when distributing the prizes and restarting the game
	uint public constant LIMIT_AMOUNT_BETS = 100;

	// The number that won the last game
	uint public numberWinner;

	// Array of players
	address payable [] public players;

	// Each number has an array of players. Associate each number with a bunch of players
	mapping(uint => address payable []) public numberBetPlayers;

	// The number that each player has bet for
	mapping(address => uint) playerBetsNumber;

	// Modifier to only allow the execution of functions when the bets are completed
	modifier onEndGame(){
		if (numberOfBets >= maxAmountOfBets) {
		    _;
		}
	}

	/// @notice Constructor that's used to configure the minimum bet per game and the max amount of bets
	/// @param _minimumBet The minimum bet that each user has to make in order to participate in the game
	/// @param _maxAmountOfBets The max amount of bets that are required for each game
	constructor (uint _minimumBet, uint _maxAmountOfBets) public {
		owner = msg.sender;

		if (_minimumBet > 0) {
		    minimumBet = _minimumBet;
		}
		
		if (_maxAmountOfBets > 0 && _maxAmountOfBets <= LIMIT_AMOUNT_BETS) {
		    maxAmountOfBets = _maxAmountOfBets;
		}

		// Set the proof of oraclize in order to make secure random number generations
// 		oraclize_setProof(proofType_Android | proofType_Ledger);
	}

	/// @notice Check if a player exists in the current game
	/// @param player The address of the player to check
	/// @return bool Returns true is it exists or false if it doesn't
	function checkPlayerExists(address player) public view returns(bool){
	    return playerBetsNumber[player] > 0;
	}
	
	/// @notice To bet for a number by sending Ether
	/// @param numberToBet The number that the player wants to bet for. Must be between 1 and 10 both inclusive
	function bet(uint numberToBet) public payable{

		// Check that the max amount of bets hasn't been met yet
		require(numberOfBets < maxAmountOfBets);

		// Check that the player doesn't exists
		require(checkPlayerExists(msg.sender) == false);

		// Check that the number to bet is within the range
		require(numberToBet >= 1 && numberToBet <= 10);

		// Check that the amount paid is bigger or equal the minimum bet
		require(msg.value >= minimumBet);

		// Set the number bet for that player
		playerBetsNumber[msg.sender] = numberToBet;

		// The player msg.sender has bet for that number
		numberBetPlayers[numberToBet].push(msg.sender);

		numberOfBets += 1;
		totalBet += msg.value;

		if (numberOfBets >= maxAmountOfBets) {
		    generateNumberWinner();
		}
	}

	/// @notice Generates a random number between 1 and 10 both inclusive.
	/// Must be payable because oraclize needs gas to generate a random number.
	/// Can only be executed when the game ends.
	function generateNumberWinner() public onEndGame returns (uint) {

// 		string memory query = "https://www.random.org/integers/?num=1&min=1&max=10&col=1&base=10&format=plain&rmd=new";
// 		bytes32 queryId = oraclize_query("URL", query);
// 		oraclize_proofShield_commitment[queryId] = keccak256(sha256(query), proofType_Android);
		
// 		uint numberRandomBytes = 7;
// 		uint delay = 0;
// 		uint callbackGas = 200000;
		return 1;

		// bytes32 queryId = oraclize_newRandomDSQuery(delay, numberRandomBytes, callbackGas);
	}

	function sliceUint (bytes memory bs, uint start) internal pure returns (uint) {
	    
	    require(bs.length >= start + 32, "slicing out of range");
	    uint x;
	    assembly {
	        x := mload(add(bs, add(0x20, start)))
	    }
	    return x;
	}

	/// @notice Callback function that gets called by oraclize when the random number is generated
	/// @param _queryId The query id that was generated to proofVerify
	/// @param _result String that contains the number generated
	/// @param _proof A string with a proof code to verify the authenticity of the number generation
	function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public onEndGame {
	// oraclize_randomDS_proofVerify(_queryId, _result, _proof) public onEndGame {

		// Checks that the sender of this callback was in fact oraclize
// 		require(msg.sender == oraclize_cbAddress());
// 		uint newUint = sliceUint(abi.encode(_result), 0);
// 		numberWinner = (uint(newUint)%10+1);
        // if (oraclize_proofShield_proofVerify__returnCode(_queryId, _result, _proof) == 0) {
            // randomInt = parseInt(_result);
        // }
		distributePrizes();
	}

	/// @notice Sends the corresponding Ether to each winner then deletes all the
	/// players for the next game and resets the `totalBet` and `numberOfBets`
	function distributePrizes() onEndGame public {
		uint winnerEtherAmount = totalBet / numberBetPlayers[numberWinner].length; // How much each winner gets

		// Loop through all the winners to send the corresponding prize for each one
		for (uint i = 0; i < numberBetPlayers[numberWinner].length; i++){
		    numberBetPlayers[numberWinner][i].transfer(winnerEtherAmount);
		}

		resetData();
	}

	function resetData() public {
	   players.length = 0; // Delete all the players array
	   totalBet = 0;
	   numberOfBets = 0;
	}
}