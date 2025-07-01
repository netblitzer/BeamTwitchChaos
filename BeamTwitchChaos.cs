using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using CrowdControl.Common;
using JetBrains.Annotations;
using ConnectorLib.SimpleTCP;
using ConnectorType = CrowdControl.Common.ConnectorType;

namespace CrowdControl.Games.Packs.BeamNG;

[UsedImplicitly]
public class BeamNG : SimpleTCPPack<SimpleTCPServerConnector> {
    public override string Host => "0.0.0.0";
    public override ushort Port => 43384;

    public override ISimpleTCPPack.MessageFormatType MessageFormat => ISimpleTCPPack.MessageFormatType.CrowdControl;
    public override ISimpleTCPPack.QuantityFormatType QuantityFormat => ISimpleTCPPack.QuantityFormatType.ParameterAndField;

    public BeamNG (UserRecord player, Func<CrowdControlBlock, bool> responseHandler, Action<object> statusUpdateHandler) : base(player, responseHandler, statusUpdateHandler) { }

    public override Game Game { get; } = new("BeamNG.Drive", "BeamNG", "PC", ConnectorType.SimpleTCPServerConnector) { Hidden = Game.HiddenState.EarlyAccess };

    public static ParameterDef GravityParameters { get; } = new ParameterDef("Gravity", "gravity", [
        new Parameter("Pluto", "grav_pluto"),
        new Parameter("Moon", "grav_moon"),
        new Parameter("Mars", "grav_mars"),
        new Parameter("Venus", "grav_venus"),
        new Parameter("Saturn", "grav_saturn"),
        new Parameter("Double Earth", "grav_double_earth"),
        new Parameter("Jupiter", "grav_jupiter")
    ]);

    public static ParameterDef SimspeedParameters { get; } = new ParameterDef("Sim Speed", "simspeed", [
        new Parameter("Real Speed", "time_1"),
        new Parameter("Half Speed", "time_2"),
        new Parameter("1/4 Speed", "time_4"),
        new Parameter("1/8 Speed", "time_8"),
        new Parameter("1/16 Speed", "time_16")
    ]);

    public const string UiEffects = "UI Effects";
    public const string VehicleEffects = "Vehicle Effects";
    public const string EnvironmentEffects = "Environment Effects";
    public const string CameraEffects = "Camera Effects";
    public const string FunEffects = "Fun Effects";
    public const string CcEffects = "Crowd Effects";

    public override EffectList Effects { get; } = new Effect[] {
        // UI effects add things to the player screen
        new("Add a DVD Logo", "dvd") { Price = 15, Description = "Something everyone in chat can watch", Quantity = new QuantityRange(1, 10), DefaultQuantity = 1, Category = UiEffects },
        new("Add an Ad", "ad") { Price = 15, Description = "You've won a new car!", Quantity = new QuantityRange(1, 10), DefaultQuantity = 1, Category = UiEffects },
        new("Narrow the Screen", "view_narrow") { Price = 40, Description = "We can see too much, can you do something about that?", Category = UiEffects },
        new("Squish the Screen", "view_squish") { Price = 40, Description = "We can see too much, can you do something about that?", Category = UiEffects },
        // new("Shake the Screen", "view_shake") { Price = 80, Description = "Add some drama", Category = new EffectGrouping("UI") },
        new("Clear the Screen", "uireset") { Price = 15, Description = "Can we see again?", Category = UiEffects },
        new("Call in Clippy", "clippy") { Price = 150, Description = "I think the streamer might need some help", Category = UiEffects },
        new("Windows Error", "windows_error") { Price = 30, Description = "Windows is a perfectly stable operating system", Category = UiEffects },

        // Vehicle effects directly change things about the player's vehicle in various ways
        new("Pop a Tire", "pop") { Price = 150, Description = "Make it a bit harder to drive", Category = VehicleEffects },
        new("Start a Fire", "fire") { Price = 400, Description = "Everyone knows Twitch likes a hot stream", Category = VehicleEffects },
        new("Explode", "explode") { Price = 1200, Description = "When the stream is going a little *too* well", Category = VehicleEffects },
        new("Extinguish", "extinguish") { Price = 25, Description = "Give the streamer a second chance", Category = VehicleEffects },
        new("Ghost", "ghost") { Price = 50, Description = "Invite a ghost to the party", Category = VehicleEffects },
        new("Toggle the Ignition", "ignition") { Price = 50, Description = "Jiggle the car keys", Category = VehicleEffects },
        new("Set off the Alarm", "alarm") { Price = 50, Description = "I think someone might be trying to break into our car", Category = VehicleEffects },
        // new("Lowrider", "slam") { Price = 150, Description = "Time to get fancy", Category = VehicleEffects },
        new("Randomize the Paint", "random_paint") { Price = 20, Description = "Let's get some fresh new paint", Category = VehicleEffects },
        // new("Randomize the Tune", "random_tune") { Price = 200, Description = "I know how to tune, trust me", Category = VehicleEffects },
        // new("Randomize the Parts", "random_part") { Price = 1000, Description = "Let's order some cool new parts", Category = VehicleEffects },
        // new("Damage a Part", "random_damage") { Price = 50, Description = "Give something a break", Category = VehicleEffects },
        // new("Repair the Car", "repair") { Price = 25, Description = "Nothing a bit of percussive maintenance can't fix", Category = VehicleEffects },
        new("Reset the Car", "reset") { Price = 100, Description = "Let's just pick up where we were", Category = VehicleEffects },
        new("Turn on the Forcefield", "forcefield") { Price = 75, Description = "Push everything away", Category = VehicleEffects },
        new("Turn on the Negative Forcefield", "attractfield") { Price = 250, Description = "Pull everything in", Category = VehicleEffects },
        new("Turn Around (Fast)", "spin") { Price = 200, Description = "I think we're going the wrong way", Category = VehicleEffects },
        new("Bump the Car Left", "nudge_l") { Price = 50, Description = "Give it a bit of a push", Category = VehicleEffects },
        new("Bump the Car Right", "nudge_r") { Price = 50, Description = "Give it a bit of a push", Category = VehicleEffects },
        new("Kick the Car Left", "kick_l") { Price = 175, Description = "Ok now you might be going too far", Category = VehicleEffects },
        new("Kick the Car Right", "kick_r") { Price = 175, Description = "Ok now you might be going too far", Category = VehicleEffects },
        new("Jump the Car", "jump_l") { Price = 100, Description = "Woah, sick jump!", Category = VehicleEffects },
        new("Jump the Car Really High", "jump_h") { Price = 300, Description = "Hang on, are you a superhero?!", Category = VehicleEffects },
        new("Tilt the Car Left", "tilt_l") { Price = 100, Description = "What's better than cow tipping?", Category = VehicleEffects },
        new("Tilt the Car Right", "tilt_r") { Price = 100, Description = "What's better than cow tipping?", Category = VehicleEffects },
        new("Do a Barrel Roll Left", "roll_l") { Price = 300, Description = "Ackshually it's not a barrel roll", Category = VehicleEffects },
        new("Do a Barrel Roll Right", "roll_r") { Price = 300, Description = "Ackshually it's not a barrel roll", Category = VehicleEffects },
        new("Give a Small Boost", "boost_l") { Price = 50, Description = "Is this one of those video games?", Category = VehicleEffects },
        new("Rocket Boost", "boost_h") { Price = 250, Description = "Time to go Sonic Fast", Category = VehicleEffects },
        new("Do a Kickflip", "kickflip") { Price = 350, Description = "Did you know you look a lot like Tony Hawk?", Category = VehicleEffects },
        // new("Skip the Car", "skip") { Price = 100, Description = "Skipping is a healthy way to move around", Category = VehicleEffects },
        new("Sticky Throttle", "sticky_throttle") { Group = "inverse_cc_effect", Price = 125, Description = "Onward!", Category = VehicleEffects },
        new("Sticky Handbrake", "sticky_parkingbrake") { Group = "inverse_cc_effect", Price = 125, Description = "Do a drift!", Category = VehicleEffects },
        new("Sticky Brake", "sticky_brake") { Group = "inverse_cc_effect", Price = 75, Description = "We're going too fast!", Category = VehicleEffects },
        new("Yank the Wheel Left", "sticky_turn_l") { Group = "inverse_cc_effect", Price = 150, Description = "Was that our exit?", Category = VehicleEffects },
        new("Yank the Wheel Right", "sticky_turn_r") { Group = "inverse_cc_effect", Price = 150, Description = "Was that our exit?", Category = VehicleEffects },

        // Camera effects change the player's camera status
        //  Most should be disabled because they only work in certain camera views
        new("Change the Camera", "camera_change") { Price = 75, Description = "What were we looking at?", Category = CameraEffects },
        new("Pan the Camera Left", "camera_left") { Price = 25, Inactive = true, Description = "This one spins us", Category = CameraEffects },
        new("Pan the Camera Right", "camera_right") { Price = 25, Inactive = true, Description = "This one spins us", Category = CameraEffects },
        new("Pan the Camera Up", "camera_up") { Price = 25, Inactive = true, Description = "This one spins us", Category = CameraEffects },
        new("Pan the Camera Down", "camera_down") { Price = 25, Inactive = true, Description = "This one spins us", Category = CameraEffects },
        new("Zoom the Camera In", "camera_in") { Price = 50, Inactive = true, Description = "This brings us closer", Category = CameraEffects },
        new("Zoom the Camera Out", "camera_out") { Price = 50, Inactive = true, Description = "This moves us further", Category = CameraEffects },
        new("Reset the Camera", "camera_reset") { Price = 15, Inactive = true, Description = "Can we see again?", Category = CameraEffects },
        //new("Mess with the Camera FOV", "camerafov") { Price = 50, Description = "This moves us further", Category = CameraEffects },

        // Environment effects change the game world in various ways
        new("Set Gravity", "gravity") { Price = 150, Description = "Hope we're not going over a jump", Parameters = GravityParameters, Category = EnvironmentEffects },
        new("Set Simulation scale", "simspeed") { Price = 100, Description = "We need to see that in slow-mo!", Parameters = SimspeedParameters, Category = EnvironmentEffects },
        new("Randomize Fog", "fog") { Price = 100, Description = "Sight is for those who don't want to crash", Category = EnvironmentEffects },
        // new("Increase Fog", "fogup") { Price = 40, Description = "Chat says \"We don't want to see\"", Category = EnvironmentEffects },
        // new("Decrease Fog", "fogdown") { Price = 40, Description = "Chat says \"Actually can we see\"", Category = EnvironmentEffects },
        // new("Set Time to Night", "nighttime") { Price = 25, Description = "Hope you still have headlights", Category = EnvironmentEffects },
        new("Set Time to Day", "daytime") { Price = 25, Description = "FLASHBANG!", Category = EnvironmentEffects },
        new("Set Time to Random", "randomtime") { Price = 25, Description = "We'll get there when we get there", Category = EnvironmentEffects },
        new("Randomize the Day/Night Cycle", "timescale") { Price = 75, Description = "What sort of universe is this?", Category = EnvironmentEffects },
        // new("Move Time Forward", "timeforward") { Price = 15, Description = "Some want the future", Category = EnvironmentEffects },
        // new("Move Time Backward", "timebackward") { Price = 15, Description = "Some want the past", Category = EnvironmentEffects },
        new("Fix the World", "fix_env") { Price = 25, Description = "Let's get this back to normal, shall we?", Category = EnvironmentEffects },

        // Fun effects are mostly dropping objects on the player's vehicle
        //new("Set AI to Random", "airandom"),
        //new("Anger the AI", "aianger") { Price = 50, Description = "Road rage time" },
        //new("Calm the AI", "aicalm") { Price = 25, Description = "Everyone's a grandma" },
        // new("Make Friends with the AI", "heyai") { Price = 25, Description = "Everyone's a villager?", Category = FunEffects },
        new("Toss a Cone to Your Streamer", "drop_cone") { Price = 5, Description = "Oh Twitch of Plenty", Category = FunEffects },
        new("Drop a Piano", "drop_piano") { Price = 75, Description = "Make some music", Category = FunEffects },
        new("Flock of Birds", "drop_flock") { Price = 500, Description = "Toss some bread crumbs in the back, I heard that attracts lots of birds", Category = FunEffects },
        new("Get a Bus", "drop_bus") { Price = 350, Description = "Looks like that's your bus, better call it over", Category = FunEffects },
        new("Hail a Cab", "drop_taxi") { Price = 175, Description = "TAXI!", Category = FunEffects },
        new("Traffic Jam", "drop_traffic") { Price = 200, Description = "Cause a traffic jam", Category = FunEffects },
        new("Get a Ramp", "drop_ramp") { Price = 200, Description = "Let's jump this thing", Category = FunEffects },
        new("Meteor Shower", "meteors") { Price = 500, Description = "Make a wish! No wait, wrong thing", Category = FunEffects },
        new("Fireworks", "fireworks") { Price = 100, Description = "Celebrate whatever you want!", Category = FunEffects },

        // Total control effects allow the chat to completely control the vehicle
        new("Take Complete Control", "cc_activate") { Price = 1000, Description = "Take complete control", SessionCooldown = SITimeSpan.FromMinutes(5), Category = CcEffects },
        new("Stay in Control", "cc_continue.1") { Group = "cc_effect", Price = 200, Description = "Stay in control for even longer", Category = CcEffects },
        new("Stay in Control", "cc_continue.2") { Group = "cc_effect", Price = 500, Description = "Stay in control for even longer", Category = CcEffects },
        new("Throttle (Off)", "cc_throttle.0") { Group = "cc_effect", Price = 2, Description = "Disengage the throttle", Category = CcEffects },
        new("Throttle (50%)", "cc_throttle.1") { Group = "cc_effect", Price = 2, Description = "Set throttle to 50%", Category = CcEffects },
        new("Throttle (100%)", "cc_throttle.2") { Group = "cc_effect", Price = 2, Description = "Set throttle to 100%", Category = CcEffects},
        new("Steer Straight (0 degrees)", "cc_straight") { Group = "cc_effect", Price = 2, Description = "Straighten the steering wheel", Category = CcEffects },
        new("Steer Left (15 degrees)", "cc_left.1") { Group = "cc_effect", Price = 2, Description = "Steer slightly left (15 degrees)", Category = CcEffects },
        new("Steer Left (30 degrees)", "cc_left.2") { Group = "cc_effect", Price = 2, Description = "Steer left (30 degrees)", Category = CcEffects },
        new("Steer Left (45 degrees)", "cc_left.3") { Group = "cc_effect", Price = 2, Description = "Steer left (45 degrees)", Category = CcEffects },
        new("Steer Right (15 degrees)", "cc_right.1") { Group = "cc_effect", Price = 2, Description = "Steer slightly right (15 degrees)", Category = CcEffects },
        new("Steer Right (30 degrees)", "cc_right.2") { Group = "cc_effect", Price = 2, Description = "Steer right (30 degrees)", Category = CcEffects },
        new("Steer Right (45 degrees)", "cc_right.3") { Group = "cc_effect", Price = 2, Description = "Steer right (45 degrees)", Category = CcEffects },
        new("Brake (Off)", "cc_brake.0") { Group = "cc_effect", Price = 2, Description = "Disengage the brakes", Category = CcEffects },
        new("Brake (50%)", "cc_brake.1") { Group = "cc_effect", Price = 2, Description = "Set brakes to 50%", Category = CcEffects },
        new("Brake (100%)", "cc_brake.2") { Group = "cc_effect", Price = 2, Description = "Set brakes to 100%", Category = CcEffects },
        new("Gear Up", "cc_gear.up") { Group = "cc_effect", Price = 2, Description = "Gear up", Category = CcEffects },
        new("Gear Down", "cc_gear.down") { Group = "cc_effect", Price = 2, Description = "Gear down", Category = CcEffects },
        new("Gear to Neutral", "cc_gear.neutral") { Group = "cc_effect", Price = 2, Description = "Set gear to neutral", Category = CcEffects },
        new("Gear to Reverse", "cc_gear.reverse") { Group = "cc_effect", Price = 2, Description = "Set gear to reverse", Category = CcEffects },
    };
}
