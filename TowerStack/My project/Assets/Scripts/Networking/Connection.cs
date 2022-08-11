using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using NativeWebSocket;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class Connection : MonoBehaviour
{
    WebSocket websocket;
    public Text eventText;
    public string websocketAddress;

    // Start is called before the first frame update
    async void Start()
    {
        DontDestroyOnLoad(gameObject); // dont destroy the Connection object when loading another scene
        websocket = new WebSocket(websocketAddress);

        websocket.OnOpen += () =>
        {
            Debug.Log("Connection open!");
        };

        websocket.OnError += (e) =>
        {
            Debug.Log("Error! " + e);
        };

        websocket.OnClose += (e) =>
        {
            Debug.Log("Connection closed!");
        };

        websocket.OnMessage += (bytes) =>
        {
             // getting the message as a string
            var message = System.Text.Encoding.UTF8.GetString(bytes);

            string currentSceneName = SceneManager.GetActiveScene().name;

            if (currentSceneName == "Game") // test
            {
                GameManager GameManagerInst = GameObject.Find("GameManager").GetComponent<GameManager>();

                //var eventString = Newtonsoft.Json.JsonConvert.SerializeObject(message);
                //Debug.Log("event serialized string" + message);

                var events = Newtonsoft.Json.JsonConvert.DeserializeObject<Dictionary<string, string>>(message);
                Debug.Log("event deserialized JSON" + events);
                string eventName = events["eventName"];
                eventText.text = eventName;
                switch (eventName)
                {
                    case "BetMade":
                        eventText.text = "success "  + eventName;

                        GameManagerInst.onBetMade(events["player"], events["ethTickerPrice"]);
                        break;
                }
        
            }
        };
        
        // Keep sending messages at every 0.3s
        InvokeRepeating("SendWebSocketMessage", 0.0f, 0.3f);

        // waiting for messages
        await websocket.Connect();
    }

    void Update()
    {
#if !UNITY_WEBGL || UNITY_EDITOR
      websocket.DispatchMessageQueue();
#endif
    }

    async void SendWebSocketMessage()
    {
        if (websocket.State == WebSocketState.Open)
        {
            // Sending bytes
            await websocket.Send(new byte[] { 10, 20, 30 });

            // Sending plain text
            await websocket.SendText("plain text message");
        }
    }

    private async void OnApplicationQuit()
    {
        await websocket.Close();
    }

}