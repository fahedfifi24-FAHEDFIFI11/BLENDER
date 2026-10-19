#include "NVGame.h"
#include "Camera/CameraComponent.h"
#include "Kismet/GameplayStatics.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/GameUserSettings.h"
#include "Engine/Engine.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Engine/World.h"

ANVGameMode::ANVGameMode(){
 DefaultPawnClass=ANVPlayer::StaticClass(); HUDClass=ANVHUD::StaticClass();
 PrimaryActorTick.bCanEverTick=true;
}
void ANVGameMode::BeginPlay(){
 Super::BeginPlay();
 Player=Cast<ANVPlayer>(UGameplayStatics::GetPlayerPawn(this,0));
 for(TActorIterator<ANVDistrict> I(GetWorld());I;++I){ District=*I; break; }
 if(!District) District=GetWorld()->SpawnActor<ANVDistrict>();
 SetCursor(true);
 if(GEngine && GEngine->GetGameUserSettings()) Quality=FMath::Clamp(GEngine->GetGameUserSettings()->GetOverallScalabilityLevel(),0,3);
}
void ANVGameMode::SetCursor(bool Visible){
 if(auto* PC=UGameplayStatics::GetPlayerController(this,0)){
  PC->bShowMouseCursor=Visible;
  PC->bShouldPerformFullTickWhenPaused=true;
  if(Visible){ FInputModeGameAndUI Input; Input.SetHideCursorDuringCapture(false); PC->SetInputMode(Input); }
  else{ FInputModeGameOnly Input; PC->SetInputMode(Input); }
 }
}
void ANVGameMode::StartJourney(){
 UGameplayStatics::SetGamePaused(this,false);
 Mode=ENVMode::Playing; Mission=ENVMission::Broker;
 DialoguePage=0; Defeated=0; HackSuccess=0; Hacking=false; FoundMemory=false; Elapsed=0;
 District->ResetDistrict(); Player->ResetOperative(); SetCursor(false);
 Say(TEXT("MARA / A ghost signal survived the purge. Find Ivo in the sunken market. He knows the old network."),9);
}
void ANVGameMode::TogglePause(){
 if(Mode==ENVMode::Playing){ Mode=ENVMode::Paused; Player->TriggerHeld=false; UGameplayStatics::SetGamePaused(this,true); SetCursor(true); }
 else if(Mode==ENVMode::Paused){ Mode=ENVMode::Playing; UGameplayStatics::SetGamePaused(this,false); SetCursor(false); }
}
void ANVGameMode::Title(){
 UGameplayStatics::SetGamePaused(this,false); Mode=ENVMode::Title;
 if(Player){ Player->TriggerHeld=false; Player->GetCharacterMovement()->StopMovementImmediately(); }
 SetCursor(true);
}
void ANVGameMode::Say(const FString& Text,float Duration){ Message=Text; MessageTime=Duration; }
float ANVGameMode::HackPhase() const { return FMath::Fmod(HackClock,2.f)/2.f; }
bool ANVGameMode::Near(FVector Position,float Range) const { return Player && FVector::Dist2D(Player->GetActorLocation(),Position)<Range && FMath::Abs(Player->GetActorLocation().Z-Position.Z)<230; }
bool ANVGameMode::CanUse(FVector Position,float Range) const {
 if(!Near(Position,Range) || Mode!=ENVMode::Playing) return false;
 FVector Point=Position+FVector(0,0,130);
 FVector Direction=(Point-Player->Camera->GetComponentLocation()).GetSafeNormal();
 if(FVector::DotProduct(Player->Camera->GetForwardVector(),Direction)<.35f) return false;
 FCollisionQueryParams Q(SCENE_QUERY_STAT(Interaction),false,Player);
 FHitResult Hit;
 // End before the object's own collision, rejecting intervening walls and cover.
 return !GetWorld()->LineTraceSingleByChannel(Hit,Player->GetActorLocation()+FVector(0,0,35),Position+FVector(0,0,130)-Direction*65,ECC_Visibility,Q);
}
void ANVGameMode::Interact(){
 if(Mode!=ENVMode::Playing) return;
 if(!FoundMemory && CanUse(District->Discovery)){
  FoundMemory=true; Player->Health=FMath::Min(125.f,Player->Health+25); Player->Ammo=18;
  Say(TEXT("ARCHIVE / 'Before the veil, our children knew the color of the sky.' Recovery patch acquired: +25 health, magazine refilled."),8);
  District->Play("terminal",District->Discovery); return;
 }
 switch(Mission){
 case ENVMission::Broker:
  if(!CanUse(District->Broker)) return;
  ++DialoguePage;
  if(DialoguePage==1) Say(TEXT("IVO / They buried the signal in Helix Nine. It is not a weapon. It is a record of what they took."),9);
  else if(DialoguePage==2) Say(TEXT("IVO / Take my access cipher. Align three pulses at the security console. When the alarm rises, the only way out is up."),9);
  else { Mission=ENVMission::Facility; Say(TEXT("CIPHER ACQUIRED / Use the access terminal at the corporate gate. E advances dialogue and operates terminals."),7); }
  break;
 case ENVMission::Facility:
  if(!CanUse(District->GateTerminal)) return;
  District->GateOpen=true; Mission=ENVMission::Hack; District->Play("door",District->GateTerminal);
  Say(TEXT("HELIX NINE / Access granted. Locate the security console. The covered lanes ahead lead to the roof stair."),7); break;
 case ENVMission::Hack:
  if(!CanUse(District->HackTerminal)) return;
  if(!Hacking){ Hacking=true; HackClock=0; HackSuccess=0; LastHackCycle=-1; Say(TEXT("ALIGN THE SIGNAL / Press E as the moving pulse crosses the cyan band. Three locks release the archive."),9); }
  else{
   int32 Cycle=FMath::FloorToInt(HackClock/2.f);
   if(Cycle==LastHackCycle){ Say(TEXT("LOCK HELD / Wait for the next pulse."),2); return; }
   float Phase=HackPhase();
   if(Phase>=.36f && Phase<=.62f){ ++HackSuccess; LastHackCycle=Cycle; District->Play("terminal",District->HackTerminal); }
   else{ HackSuccess=FMath::Max(0,HackSuccess-1); Say(TEXT("SIGNAL DRIFT / One lock lost. Follow the moving pulse; E inside the cyan band."),3); }
   if(HackSuccess>=3){ Hacking=false; Mission=ENVMission::Combat; District->SpawnSecurity(); District->Play("scan",District->HackTerminal); Say(TEXT("MARA / Archive secured. Security is converging. Use cover; reload with R. Clear the roof access."),8); }
  }
  break;
 case ENVMission::Rooftop:
  if(!CanUse(District->Extraction,320)) return;
  Mission=ENVMission::Complete; Mode=ENVMode::Victory; Player->TriggerHeld=false;
  Player->GetCharacterMovement()->StopMovementImmediately(); District->Play("ending",District->Extraction);
  SetCursor(true); break;
 default:break;
 }
}
void ANVGameMode::EnemyDefeated(){
 if(Mode!=ENVMode::Playing || Mission!=ENVMission::Combat) return;
 ++Defeated;
 if(Defeated>=5){ Mission=ENVMission::Rooftop; District->RoofOpen=true; Say(TEXT("MARA / Roof access is clear. Take the illuminated stair on the east side. Extraction is waiting above the amber veil."),9); }
}
void ANVGameMode::Die(){ Mode=ENVMode::Dead; Player->TriggerHeld=false; Player->GetCharacterMovement()->DisableMovement(); SetCursor(true); }
FVector ANVGameMode::Target() const {
 if(!District) return FVector::ZeroVector;
 switch(Mission){
 case ENVMission::Broker:return District->Broker;
 case ENVMission::Facility:return District->GateTerminal;
 case ENVMission::Hack:return District->HackTerminal;
 case ENVMission::Combat:
  for(auto* E:District->Enemies) if(IsValid(E)&&!E->Dead) return E->GetActorLocation();
  return District->HackTerminal;
 case ENVMission::Rooftop:return District->Extraction;
 default:return District->Extraction;
 }
}
FString ANVGameMode::Objective() const {
 switch(Mission){
 case ENVMission::Broker:return TEXT("01 / Find Ivo in the sunken market. Follow the cyan MARKET sign on the left.");
 case ENVMission::Facility:return TEXT("02 / Enter Helix Nine. Authenticate at the corporate gate terminal.");
 case ENVMission::Hack:return Hacking?TEXT("03 / Align three signal pulses. E inside the cyan timing window."):TEXT("03 / Locate and hack the security console inside Helix Nine.");
 case ENVMission::Combat:return FString::Printf(TEXT("04 / Survive the security response. Neutralized: %d / 5. Use solid cover."),Defeated);
 case ENVMission::Rooftop:return TEXT("05 / Escape via the illuminated east stair. Reach the rooftop extraction terminal.");
 default:return TEXT("GHOST SIGNAL / Archive delivered. The city remembers.");
 }
}
FString ANVGameMode::Prompt() const {
 if(Mode!=ENVMode::Playing) return TEXT("");
 if(!FoundMemory && CanUse(District->Discovery)) return TEXT("[ E ] Recover a hidden memory / suit patch");
 if(Mission==ENVMission::Broker && CanUse(District->Broker)) return TEXT("[ E ] Talk to Ivo / continue dialogue");
 if(Mission==ENVMission::Facility && CanUse(District->GateTerminal)) return TEXT("[ E ] Authenticate corporate gate");
 if(Mission==ENVMission::Hack && CanUse(District->HackTerminal)) return Hacking?TEXT("[ E ] Lock signal pulse"):TEXT("[ E ] Hack security console");
 if(Mission==ENVMission::Rooftop && CanUse(District->Extraction,320)) return TEXT("[ E ] Upload the ghost signal / extract");
 return TEXT("");
}
void ANVGameMode::Tick(float D){
 Super::Tick(D);
 if(!Player) Player=Cast<ANVPlayer>(UGameplayStatics::GetPlayerPawn(this,0));
 if(!Player || Mode!=ENVMode::Playing) return;
 Elapsed+=D; MessageTime=FMath::Max(0.f,MessageTime-D);
 if(Hacking){ HackClock+=D; if(!Near(District->HackTerminal,320)){ Hacking=false; HackSuccess=0; Say(TEXT("LINK LOST / Return to the console to reconnect."),4); } }
 if(District->ObjectiveMarker){
  District->ObjectiveMarker->SetWorldLocation(Target()+FVector(0,0,235));
  District->ObjectiveMarker->SetWorldRotation((Player->Camera->GetComponentLocation()-District->ObjectiveMarker->GetComponentLocation()).Rotation());
 }
}
void ANVGameMode::CycleQuality(){
 Quality=(Quality+1)%4;
 if(auto* Settings=GEngine?GEngine->GetGameUserSettings():nullptr){ Settings->SetOverallScalabilityLevel(Quality); Settings->ApplySettings(false); Settings->SaveSettings(); }
}
void ANVGameMode::CycleAudio(){ AudioVolume=AudioVolume>.95f?0.f:AudioVolume+.25f; AudioVolume=FMath::Clamp(AudioVolume,0.f,1.f); if(District) District->SetAudio(AudioVolume); }
