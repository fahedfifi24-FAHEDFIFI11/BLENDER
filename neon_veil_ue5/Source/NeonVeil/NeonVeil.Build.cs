using UnrealBuildTool;
public class NeonVeil : ModuleRules {
    public NeonVeil(ReadOnlyTargetRules Target) : base(Target) {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new string[] {
            "Core", "CoreUObject", "Engine", "InputCore", "NavigationSystem", "AIModule"
        });
    }
}
