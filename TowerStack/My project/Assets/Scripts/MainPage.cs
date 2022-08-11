using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MainPage : MonoBehaviour
{
    public Transform CoinHolder;

    public GameObject Coin;
    public GameObject CoinTube;
    public GameObject PlayerContainer; // width is 55

    public Canvas PlayerCanvas; // width is 640

    public int playerCount = 1;

    const float CANVAS_OFFSET = 7f;

    private int maxToppleHeight = 20;
    private int minToppleHeight = 13;

    public bool isLooping;
    private float restartDelay = 7; // seconds

    // Start is called before the first frame update
    void Start()
    {
        isLooping = false;

        GameObject PlayerContainerInst = Instantiate(PlayerContainer, PlayerCanvas.transform);
        PlayerContainerInst.transform.localPosition = new Vector2(0, 0);

        GameObject CoinTubeInst = Instantiate(CoinTube);

        Vector3 uiWorldPos = PlayerContainerInst.transform.position;
        CoinTubeInst.transform.position = new Vector3(uiWorldPos.x, -30, uiWorldPos.z - CANVAS_OFFSET);

        StartCoroutine(loopMainPageAnimation(new Player(PlayerContainerInst, "0xsomething", CoinTubeInst)));

    }

    // run the main loop of the animation
    IEnumerator loopMainPageAnimation(Player PlayerInst)
    {
        while (true)
        {
            if (!isLooping)
            {
                isLooping = true;
                int randToppleHeight = Random.Range(minToppleHeight, maxToppleHeight);
                StartCoroutine(playAnimation(PlayerInst, randToppleHeight));
            }
            yield return new WaitForEndOfFrame();
        }
    }

    // when a player loses their tower of ocins will topple and be lost
    IEnumerator toppleTower(Player PlayerInst)
    {
        if (PlayerInst.CoinTubeInst != null)
        {
            PlayerInst.CoinTubeInst.SetActive(false);
        }
        yield return new WaitForSeconds(restartDelay);
        PlayerInst.CoinTower.ForEach((GameObject CoinInst) =>
        {
            Destroy(CoinInst);
        });
        PlayerInst.clearCoinTower();
        isLooping = false;
    }

    // award players who won with coins
    IEnumerator playAnimation(Player PlayerInst, int cointCount)
    {
        PlayerInst.CoinTubeInst.SetActive(true);
        for (int i = 0; i < cointCount; i++)
        {
            yield return new WaitForSeconds(1.5f);
            GameObject CoinInst = Instantiate(Coin, CoinHolder);
            Vector3 uiWorldPos = PlayerInst.ContainerInst.transform.position;
            CoinInst.transform.position = new Vector3(uiWorldPos.x, 70, uiWorldPos.z - CANVAS_OFFSET);
            PlayerInst.incrementToken(CoinInst);
        }
        StartCoroutine(toppleTower(PlayerInst));
    }
}
