using System.Collections;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class Grid : MonoBehaviour
{
    [SerializeField]
    int xSize, ySize;
}
