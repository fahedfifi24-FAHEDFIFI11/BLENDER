using UnityEngine;
namespace NeonRequiem {
 public sealed class AmbientMotion : MonoBehaviour {
  public Vector3 rotationSpeed;public float floatAmount;public float phase;
  public Renderer animatedSurface;public Vector2 uvSpeed;Vector3 origin;MaterialPropertyBlock block;
  void Awake(){origin=transform.localPosition;if(animatedSurface)block=new MaterialPropertyBlock();}
  void Update(){float t=Time.time+phase;transform.Rotate(rotationSpeed*Time.deltaTime,Space.Self);transform.localPosition=origin+Vector3.up*Mathf.Sin(t*.8f)*floatAmount;
   if(animatedSurface&&uvSpeed!=Vector2.zero){animatedSurface.GetPropertyBlock(block);block.SetVector("_BaseColorMap_ST",new Vector4(1,1,t*uvSpeed.x,t*uvSpeed.y));animatedSurface.SetPropertyBlock(block);}
  }
 }
}
