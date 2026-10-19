using UnityEngine;
namespace NeonRequiem {
 // The supplied entry scene is deliberately explicit until the real Unity import/build pass runs.
 public sealed class BuildRequired : MonoBehaviour {
  void OnGUI(){GUI.Label(new Rect(30,30,1000,120),"NEON REQUIEM source project\nRun Neon Requiem > Generate District in the Unity Editor, then open Assets/NR/Scenes/LowTide.unity.\nThe source archive has not been compiled or playtested in Unity.");}
 }
}
