using UnrealBuildTool;
using System.Collections.Generic;
public class NeonVeilTarget : TargetRules {
    public NeonVeilTarget(TargetInfo Target) : base(Target) {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
        ExtraModuleNames.Add("NeonVeil");
    }
}
