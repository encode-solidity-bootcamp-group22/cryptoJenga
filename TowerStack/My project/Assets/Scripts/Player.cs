using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player
{
    public List<GameObject> CoinTower { get; private set; }
    public GameObject ContainerInst { get; private set; }
    public GameObject CoinTubeInst { get; private set; }

    public string address { get; private set; }
    public int tokenCount { get; private set; }

    public Player(GameObject PlayerContainer, string address, GameObject CoinTubeHolder)
    {
        ContainerInst = PlayerContainer;
        this.address = address;
        CoinTower = new List<GameObject>();
        CoinTubeInst = CoinTubeHolder;
    }

    public void clearCoinTower()
    {
        this.CoinTower = new List<GameObject>();
    }

    public void incrementToken(GameObject token)
    {
        CoinTower.Add(token);
    }
}
