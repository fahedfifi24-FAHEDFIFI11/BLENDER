#include "NVGame.h"
#include "Engine/World.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "GameFramework/PlayerController.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"

void ANVHUD::Text(const FString& Value,float X,float Y,float Scale,FLinearColor Color){ DrawText(Value,Color,X*SX,Y*SY,GEngine->GetMediumFont(),Scale*SX,false); }
void ANVHUD::Button(FName Action,const FString& Label,float X,float Y,float Width){
 float MX=0,MY=0; GetOwningPlayerController()->GetMousePosition(MX,MY);
 FBox2D Rect(FVector2D(X*SX,Y*SY),FVector2D((X+Width)*SX,(Y+54)*SY));
 bool Hover=Rect.IsInside(FVector2D(MX,MY));
 DrawRect(Hover?FLinearColor(.09f,.25f,.29f,.97f):FLinearColor(.025f,.09f,.12f,.96f),X*SX,Y*SY,Width*SX,54*SY);
 Text(Label,X+18,Y+13,1.05f);
 Buttons.Add({Action,Rect});
}
void ANVHUD::DrawHUD(){
 Super::DrawHUD(); if(!Canvas) return;
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>(); if(!G || !G->Player) return;
 SX=Canvas->ClipX/1920.f; SY=Canvas->ClipY/1080.f; Buttons.Empty();
 auto* P=G->Player;
 if(G->Mode==ENVMode::Playing){
  Text(TEXT("N / V     GHOST SIGNAL"),48,35,1.1f,FLinearColor(.45f,.82f,.85f));
  DrawRect(FLinearColor(.03f,.07f,.09f,.8f),48*SX,82*SY,320*SX,13*SY);
  DrawRect(FLinearColor(.3f,.72f,.7f),48*SX,82*SY,320*SX*FMath::Clamp(P->Health/100.f,0.f,1.f),13*SY);
  Text(FString::Printf(TEXT("SUIT %d    /    MAG %02d | 18"),FMath::CeilToInt(P->Health),P->Ammo),48,108,.85f);
  if(P->ReloadTime>0) Text(TEXT("RELOADING"),48,138,.85f,FLinearColor(1,.6f,.3f));
  Text(G->Objective(),48,930,1.05f);
  Text(FString::Printf(TEXT("SIGNAL  %dm"),FMath::RoundToInt(FVector::Dist(P->GetActorLocation(),G->Target())/100)),48,970,.9f,FLinearColor(.4f,.8f,.85f));
  Text(TEXT("WASD move / Mouse look / Shift sprint / Ctrl crouch / Space jump / RMB aim / LMB fire / R reload / E interact / Esc pause"),48,1038,.7f);
  Text(G->Prompt(),620,675,1.05f,FLinearColor(.6f,.95f,.92f));
  if(G->MessageTime>0) Text(G->Message,90,850,.85f,FLinearColor(.92f,.8f,.65f));
  FLinearColor Cross=P->HitFlash>0?FLinearColor(1,.3f,.15f):FLinearColor(.7f,.87f,.9f,.8f);
  DrawLine(955*SX,540*SY,965*SX,540*SY,Cross,1); DrawLine(960*SX,535*SY,960*SX,545*SY,Cross,1);
  if(G->Hacking){
   DrawRect(FLinearColor(.01f,.025f,.035f,.95f),620*SX,735*SY,680*SX,68*SY);
   DrawRect(FLinearColor(.05f,.45f,.49f,.95f),(640+640*.36f)*SX,755*SY,640*.26f*SX,17*SY);
   DrawRect(FLinearColor(.9f,.85f,.66f),(640+640*G->HackPhase())*SX,747*SY,4*SX,33*SY);
   Text(FString::Printf(TEXT("LOCKS %d / 3  —  E IN CYAN BAND"),G->HackSuccess),725,805,.85f);
  }
  return;
 }
 DrawRect(FLinearColor(.005f,.015f,.025f,.78f),0,0,Canvas->ClipX,Canvas->ClipY);
 Text(TEXT("N E O N   V E I L"),175,180,3.5f,FLinearColor(.75f,.9f,.91f));
 Text(TEXT("G H O S T   S I G N A L"),180,270,1.35f,FLinearColor(.92f,.65f,.4f));
 if(G->Mode==ENVMode::Title){
  Text(TEXT("A stolen memory. A city beneath the veil. One route out."),180,335,1.05f);
  Button("Start",TEXT("BEGIN MISSION"),180,420);
 }else if(G->Mode==ENVMode::Paused){
  Text(TEXT("SIGNAL PAUSED"),180,335,1.2f); Button("Resume",TEXT("RESUME"),180,420);
 }else if(G->Mode==ENVMode::Dead){
  Text(TEXT("CONNECTION LOST / The archive remains inside Helix Nine."),180,335,1.05f); Button("Start",TEXT("RESTART MISSION"),180,420);
 }else{
  Text(TEXT("TRANSMISSION COMPLETE / The city remembers the daylight."),180,335,1.05f);
  Text(FString::Printf(TEXT("Security neutralized: %d / 5   Memory recovered: %s   Time: %02d:%02d"),G->Defeated,G->FoundMemory?TEXT("YES"):TEXT("NO"),int32(G->Elapsed)/60,int32(G->Elapsed)%60),180,375,.9f);
  Button("Start",TEXT("REPLAY GHOST SIGNAL"),180,420);
 }
 const TCHAR* Presets[]={TEXT("LOW"),TEXT("MEDIUM"),TEXT("HIGH"),TEXT("EPIC")};
 Button("Quality",FString::Printf(TEXT("GRAPHICS / %s"),Presets[FMath::Clamp(G->Quality,0,3)]),180,490);
 Button("Audio",FString::Printf(TEXT("AUDIO / %d%%"),FMath::RoundToInt(G->AudioVolume*100)),180,560);
 if(G->Mode!=ENVMode::Title) Button("Title",TEXT("RETURN TO TITLE"),180,630);
 Button("Quit",TEXT("EXIT TO WINDOWS"),180,700);
 Text(TEXT("Cover blocks shots. Watch security windups. E advances broker dialogue."),180,800,.9f);
 Text(TEXT("Cyan markers guide the main route. Search the shopfront archive for a recovery patch."),180,840,.85f);
}
void ANVHUD::Click(){
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>(); if(!G) return;
 float X=0,Y=0; if(!GetOwningPlayerController()->GetMousePosition(X,Y)) return;
 for(const auto& B:Buttons){ if(!B.Bounds.IsInside(FVector2D(X,Y))) continue;
  if(B.Action=="Start") G->StartJourney();
  else if(B.Action=="Resume") G->TogglePause();
  else if(B.Action=="Title") G->Title();
  else if(B.Action=="Quality") G->CycleQuality();
  else if(B.Action=="Audio") G->CycleAudio();
  else if(B.Action=="Quit") UKismetSystemLibrary::QuitGame(this,GetOwningPlayerController(),EQuitPreference::Quit,false);
  break;
 }
}
