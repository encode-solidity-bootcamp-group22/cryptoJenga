using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

#if UNITY_WEBGL
public class WebGLSendTransactionExample : MonoBehaviour
{
    public GameObject AdmitButton;
    public CryptoJenga JengaContract;

    string to = "0x428066dd8A212104Bc9240dCe3cdeA3D3A0f7979";

    public void onExit()
    {
        SceneManager.LoadScene("GameLogin");
    }

    public void onGrantAdmission()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1);
    }

    async public void OnSendTransaction()
    {
        try
        {
            string to = "0x428066dd8A212104Bc9240dCe3cdeA3D3A0f7979";
            // amount in wei to send
            string value = "12300000000000";
            // gas limit OPTIONAL
            string gasLimit = "";
            // gas price OPTIONAL
            string gasPrice = "";
            string response = await Web3GL.SendTransaction(to, value, gasLimit, gasPrice);
            Debug.Log(response);
            AdmitButton.SetActive(true);
        }
        catch (Exception e)
        {
            Debug.LogException(e, this);
        }

        // wei in a ether 1000000000000000000
        //float value = 123000000000000; // get ticket price

        //try {
        //    Debug.Log("Placing bet");
        //    int gameId = 0;
        //    int roundNumber = 0;
        //    await JengaContract.Bet(gameId, roundNumber, value.ToString());
        //    Debug.Log("Placed Bet");
        //    AdmitButton.SetActive(true);
        //} catch (Exception e) {
        //    Debug.LogException(e, this);
        //}
    }
}
#endif