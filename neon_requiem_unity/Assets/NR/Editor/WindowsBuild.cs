using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;
namespace NeonRequiem.Editor {
 public static class WindowsBuild {
  [MenuItem("Neon Requiem/Build Windows x64")]
  public static void Build(){
   if(!BuildPipeline.IsBuildTargetSupported(BuildTargetGroup.Standalone,BuildTarget.StandaloneWindows64))throw new Exception("Install Unity 6000.0 Windows Build Support through Unity Hub.");
   DistrictBuilder.Generate();SceneValidation.Validate();
   PlayerSettings.SetScriptingBackend(NamedBuildTarget.Standalone,ScriptingImplementation.Mono2x);
   Directory.CreateDirectory("Builds/Windows");
   var result=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{"Assets/NR/Scenes/LowTide.unity"},locationPathName="Builds/Windows/NeonRequiem.exe",target=BuildTarget.StandaloneWindows64,options=BuildOptions.StrictMode});
   if(result.summary.result!=BuildResult.Succeeded)throw new Exception("Windows build failed: "+result.summary.result+" errors="+result.summary.totalErrors);
   foreach(string required in new[]{"Builds/Windows/NeonRequiem.exe","Builds/Windows/UnityPlayer.dll","Builds/Windows/NeonRequiem_Data/globalgamemanagers"})if(!File.Exists(required))throw new Exception("Incomplete output: "+required);
   File.Copy("PLAYER_README.txt","Builds/Windows/READ_ME.txt",true);
   File.WriteAllText("Builds/BUILD_RECEIPT.json","{\"editor\":\""+Application.unityVersion+"\",\"result\":\"Succeeded\",\"bytes\":"+result.summary.totalSize+",\"playtested\":false}");
   Debug.Log("NEON_REQUIEM_WINDOWS_BUILD_EXISTS. Launch and complete the manual acceptance route before calling it tested.");
  }
 }
}
