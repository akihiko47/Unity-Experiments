using UnityEngine;
using System;

public class Clock : MonoBehaviour {

    [SerializeField]
    Transform hourPivot, minutePivot, secondPivot;

    void Update () {
        TimeSpan time = DateTime.Now.TimeOfDay;
        hourPivot.localRotation =  Quaternion.Euler(0f, 0f, -30f * (float)time.TotalHours);
        minutePivot.localRotation =  Quaternion.Euler(0f, 0f, -6f * (float)time.TotalMinutes);
        secondPivot.localRotation =  Quaternion.Euler(0f, 0f, -6f * (float)time.TotalSeconds);
    }
}