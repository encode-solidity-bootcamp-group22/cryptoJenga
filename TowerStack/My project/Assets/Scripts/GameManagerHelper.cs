using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManagerHelper : MonoBehaviour
{
    public static Player findPlayer(List<Player> PlayerList, string address)
    {
        return PlayerList.Find((Player PlayerInst) => PlayerInst.address == address);
    }

    // given a list of addresses, find the corresponding list of players
    public static List<Player> getPlayerListFromAddresses(List<Player> PlayerList, List<string> addressList)
    {
        List<Player> MatchingPlayerList = new List<Player>();
        addressList.ForEach((string address) =>
        {
            Player MatchingPlayer = PlayerList.Find((Player player) => player.address == address);
            MatchingPlayerList.Add(MatchingPlayer);
        });
        return MatchingPlayerList;
    }
}
