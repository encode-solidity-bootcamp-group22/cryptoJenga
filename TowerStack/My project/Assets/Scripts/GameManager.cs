using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using System.Threading.Tasks;

public class GameManager : MonoBehaviour
{
    public Transform CoinHolder;
    public Transform CoinTubeHolder;

    public GameObject Coin;
    public GameObject CoinTube;
    public GameObject PlayerContainer; // width is 55

    public Text GameStatusText;
    public Text CurrentRoundText;
    public Button BetButton;
    public InputField BetTextInput;

    public CryptoJenga JengaContract;

    List<Player> PlayerList;

    public Canvas PlayerCanvas; // width is 640

    const float PlayerContainerWidth = 100;
    const float padding = 25f;

    const float CANVAS_OFFSET = 7f;

    int currentRound;
    int gameId = 0;

    List<string> PlayerAddressList;
    int playerIdx = 0;

    List<int> Round1WinnerOrder = new List<int> { 0, 5, 3, 1, 4, 2 };
    List<int> Round2WinnerOrder = new List<int> { 2,5,1,4,3,0 };
    List<int> Round3WinnerOrder = new List<int> { 3,1,5,0,2,3 };
    List<List<int>> RoundWinners = new List<List<int>>();
    // Start is called before the first frame update

    //0 6 0 2 = 2
    //1 3 3 4 = 10
    //2 1 6 1 = 8
    //3 4 1 5 = 10
    //4 0 2 0 = 0
    //5 5 4 3 = 11
    //6 2 5 6 = 13

    void Start()
    {
        // TODO: max number of players is 10
        PlayerList = new List<Player>();
        PlayerAddressList = new List<string>();
        currentRound = 0;

        RoundWinners.Add(Round1WinnerOrder);
        RoundWinners.Add(Round2WinnerOrder);
        RoundWinners.Add(Round3WinnerOrder);

        //initPlayerAddresses(); // Commmented for testings
        PlayerAddressList = new List<string>() { "0x2A4..5E3", "0x76B..DDA", "0xB62..06B", "0xE17..4B4", "0x5AD..D9C", "0x41D..D92" };
        StartCoroutine(testEndGame());
    }

    // when user exits game load main screen
    public void onExit()
    {
        SceneManager.LoadScene("Lobby");
    }

    //event RequestedRandomness(bytes32 requestId);

    //event BetMade(address _player, uint256 _EthTicketPrice);
    public void onBetMade(string address, string ethTicketPrice)
    {
        if (currentRound == 0 && !PlayerAddressList.Contains(address))
        {
            PlayerAddressList.Add(address);
            initPlayerContainers(PlayerAddressList);
        }
    }

    public void onReceiveMessage(string test)
    {
    }

    //event GameState(string _currentState);
    public void onGameState(string currentState)
    {
        if (currentState == "Open")
        {
            GameStatusText.text = "Open For Bets";
            BetButton.interactable = true;
        }
        // the game has ended
        else if (currentState == "Closed") 
        {
            GameStatusText.text = "Game Over";
            BetButton.interactable = false;
        }
    }
    //event RoundStarted(uint256 _currentRoundNumber);
    public void onRoundStarted(int currentRoundNumber)
    {
        BetButton.interactable = true;
        currentRound = currentRoundNumber;
        CurrentRoundText.text = "Round " + currentRoundNumber;
    }

    public void onRoundEnded(int currentRoundNumber)
    {
        BetButton.interactable = false;
    }

    // distributes the winnings in a round (excluding the last round)
    public void onRoundWinningsAnnounced(string address, int winnings)
    {
        rewardPlayer(address, winnings);
    }

    // when final round ends the game ended, and the winner is announced
    public void onGameEnded(string address, int totalWinnings)
    {
        endGame(address);
    }

    // updates the number of players and positions the player UI in canvas
    // @playerCount total number of players in the game
    void initPlayerContainers(List<string> playerAddressList)
    {
        clearPlayerList();

        float totalWidth = playerAddressList.Count * PlayerContainerWidth + (playerAddressList.Count - 1) * padding;
        for (int i = 0; i < playerAddressList.Count; i++)
        {
            string playerAddress = playerAddressList[i];
            float offset = (PlayerContainerWidth + padding) * i + (PlayerContainerWidth/2);
            float centerOffset = totalWidth / 2;
            float xPos = offset - centerOffset;

            GameObject PlayerContainerInst = Instantiate(PlayerContainer, PlayerCanvas.transform);


            PlayerContainerInst.transform.localPosition = new Vector2(xPos, 0);
            //PlayerContainerInst. // SET ADDRESS HERE
            GameObject CoinTubeInst = Instantiate(CoinTube, CoinTubeHolder);

            Transform addressTextTransform = PlayerContainerInst.transform.Find("AddressText");
            addressTextTransform.GetComponent<Text>().text = playerAddress;

            PlayerList.Add(new Player(PlayerContainerInst, playerAddress, CoinTubeInst));

            Vector3 uiWorldPos = PlayerContainerInst.transform.position;
            CoinTubeInst.transform.position = new Vector3(uiWorldPos.x, -20, uiWorldPos.z - CANVAS_OFFSET);

        }
    }

    // When adding a new player need to reinitialize the UIs associated with players, to redraw the screen
    void clearPlayerList()
    {
        PlayerList.ForEach((Player PlayerInst) =>
        {
            Destroy(PlayerInst.ContainerInst);
            Destroy(PlayerInst.CoinTubeInst);
        });
        PlayerList.Clear();
    }

    // TEST
    string testRewardAllPlayers(List<int>RoundWinner)
    {
        string loser = "";
        int maxReward = 0;

        RoundWinner.ForEach((int roundWinnerIdx) =>
        {

            string playerAddress = PlayerAddressList[roundWinnerIdx];

            maxReward++;
            Debug.Log("reward is " + maxReward);
            if (maxReward == RoundWinner.Count)
            {
                loser = playerAddress;
                Debug.Log("Loser is " + loser);
            }
            else
            {
                StartCoroutine(rewardPlayer(playerAddress, maxReward));
            }
            return;
        });
        return loser;
    }

    // TEST
    IEnumerator testEndGame()
    {
        Debug.Log("Test end game");

        initPlayerContainers(PlayerAddressList);
        //yield return new WaitForSeconds(5); // wait for all players to be rewarded before ending the game

        //PlayerAddressList.Add("0x76B..DDA");
        //initPlayerContainers(PlayerAddressList);

        // test game
        for (int i = 0; i < 3; i++)
        {
            int currentRound = i + 1;
            Debug.Log("round is " + currentRound);
            CurrentRoundText.text = "Round " + currentRound.ToString();

            yield return new WaitForSeconds(15);
            GameStatusText.text = "Calculating Round Winner";
            //yield return new WaitForSeconds(15);
            BetButton.interactable = false;
            List<int> RoundWinner;
            if (i == 0)
            {
                RoundWinner = Round1WinnerOrder;
            }
            else if (i == 1)
            {
                RoundWinner = Round2WinnerOrder;
            }
            else
            {
                RoundWinner = Round3WinnerOrder;
            }
            //yield return new WaitForSeconds(15); // wait for all players to be rewarded before ending the game
            string loser = testRewardAllPlayers(RoundWinner);
            yield return new WaitForSeconds(10); // wait for all players to be rewarded before ending the game
            StartCoroutine(toppleTower(loser, false));
            GameStatusText.text = "Open For Bets";
            // place bets here]

        }
        GameStatusText.text = "Decided Game Winner";
        string winnerAddress = PlayerAddressList[5];
        endGame(winnerAddress);
    }

    public async void initPlayerAddresses()
    {
        try
        {
            Task<string> t1 = Task.Run(() => JengaContract.GetPlayerAddresses());
            var res = Task.WhenAll(t1);
            // TODO: Parse response and get all player addresses here
            Debug.Log("init PlayerAddressList Here using response: " + res);
        }
        catch (System.Exception e)
        {
            Debug.Log(e.Message);
        }
    }

    public async void placeBet()
    {
        JengaContract.mockBet();
        //float value;
        //try
        //{
        //    if (float.TryParse(BetTextInput.text, out value))
        //    {
        //        float decimals = 1000000000000000000; // 18 decimals
        //        string wei = (value * decimals).ToString();
        //        Debug.Log("wei is " + wei);
        //        Task<string> t1 = Task.Run(() => JengaContract.Bet(gameId, currentRound, wei));
        //        var res = Task.WhenAll(t1);
        //    }
        //}
        //catch (System.Exception e)
        //{
        //    Debug.Log(e.Message);
        //}
        //BetTextInput.text = "";
    }

    // when a player loses their tower of ocins will topple and be lost
    IEnumerator toppleTower(string playerAddress, bool isendgame)
    {
        Player PlayerInst = GameManagerHelper.findPlayer(PlayerList, playerAddress);
        if (PlayerInst.CoinTubeInst != null)
        {
            PlayerInst.CoinTubeInst.SetActive(false);
        }
        if (!isendgame)
        {
        }
        else
        {
            yield return new WaitForSeconds(15);
        }
        PlayerInst.CoinTower.ForEach((GameObject CoinInst) =>
        {
            Destroy(CoinInst);
        });
        PlayerInst.clearCoinTower();
    }

    // award players who won with coins
    IEnumerator rewardPlayer(string playerAddress, int cointCount)
    {
        Player PlayerInst = GameManagerHelper.findPlayer(PlayerList, playerAddress);
        PlayerInst.CoinTubeInst.SetActive(true);
        for (int i = 0; i < cointCount; i++)
        {
            yield return new WaitForSeconds(1.5f);
            GameObject CoinInst = Instantiate(Coin, CoinHolder);
            Vector3 uiWorldPos = PlayerInst.ContainerInst.transform.position;
            CoinInst.transform.position = new Vector3(uiWorldPos.x, 70, uiWorldPos.z - CANVAS_OFFSET);
            PlayerInst.incrementToken(CoinInst);
        }
    }


    // ends the game in a winner-take-all scheme
    void endGame(string winnerAddress)
    {
        List<string> LoserAddressList = new List<string>(PlayerAddressList);
        bool isWinnerRemoved = LoserAddressList.Remove(winnerAddress);

        if (isWinnerRemoved)
        {
            List<Player> LosingPlayers = GameManagerHelper.getPlayerListFromAddresses(PlayerList, LoserAddressList);
            int winningsPool = 0;
            LosingPlayers.ForEach((Player PlayerInst) =>
            {
                winningsPool += PlayerInst.CoinTower.Count;
                StartCoroutine(toppleTower(PlayerInst.address, true));
            });
            StartCoroutine(rewardPlayer(winnerAddress, winningsPool));
        }
    }
}
