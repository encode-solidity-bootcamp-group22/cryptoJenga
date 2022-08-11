using System;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.SceneManagement;


#if UNITY_WEBGL
public class WebLogin : MonoBehaviour
{
    [DllImport("__Internal")]
    private static extern void Web3Connect();

    [DllImport("__Internal")]
    private static extern string ConnectAccount();

    [DllImport("__Internal")]
    private static extern void SetConnectAccount(string value);

    private string account;

    public void OnPlay()
    {
        // pay entrance fee
        // listen for paid fee event
        // if fee paid call
        Debug.Log("Enter Game");
        EnterGame();
    }

    public void EnterGame()
    {
        Web3Connect();
        OnConnected();
    }

    async private void OnConnected()
    {
        Debug.Log("attempt to connect");

        account = ConnectAccount();
        while (account == "")
        {
            await new WaitForSeconds(1f);
            account = ConnectAccount();
        };
        // save account for next scene
        PlayerPrefs.SetString("Account", account);
        // reset login message
        SetConnectAccount("");
        // load next scene
        Debug.Log("build index " + (SceneManager.GetActiveScene().buildIndex + 1));

        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1);
    }


    public void OnExit()
    {
        Application.Quit();
    }

    public void OnSkip()
    {
        // burner account for skipped sign in screen
        PlayerPrefs.SetString("Account", "");
        // move to next scene
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1);
    }
}
#endif
