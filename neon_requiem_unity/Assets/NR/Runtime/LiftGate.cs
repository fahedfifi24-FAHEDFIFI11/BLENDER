using UnityEngine;
namespace NeonRequiem {
 public sealed class LiftGate : MonoBehaviour {
  public MissionStage openAt=MissionStage.RestorePower;Vector3 closed;float lift;
  void Awake(){closed=transform.position;}
  void Update(){if(Session.Instance==null)return;bool open=Session.Instance.rules.Stage>=openAt;lift=Mathf.MoveTowards(lift,open?4.5f:0,Time.deltaTime*1.1f);transform.position=closed+Vector3.up*lift;}
 }
}
