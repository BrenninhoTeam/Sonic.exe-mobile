package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxState;
import openfl.events.Event;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import flixel.util.FlxTimer;
import flixel.FlxSprite;

#if desktop
import vlc.VlcBitmap;
#end

class MP4Handler
{
	public static var video:Video;
	public static var netStream:NetStream;
	public static var finishCallback:FlxState;

	public var sprite:FlxSprite;

	#if desktop
	public static var vlcBitmap:VlcBitmap;
	#end

	public function new()
	{
		FlxG.autoPause = false;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
	}

	public function playMP4(
		path:String,
		callback:FlxState,
		?outputTo:FlxSprite = null,
		?repeat:Bool = false,
		?isWindow:Bool = false,
		?isFullscreen:Bool = false
	):Void
	{
		finishCallback = callback;

		#if mobile

		finishVideo();

		#elseif html5

		video = new Video();

		video.x = 0;
		video.y = 0;

		FlxG.addChildBelowMouse(video);

		var nc = new NetConnection();
		nc.connect(null);

		netStream = new NetStream(nc);

		netStream.client = {
			onMetaData: client_onMetaData
		};

		nc.addEventListener("netStatus", netConnection_onNetStatus);

		netStream.play(path);

		#elseif desktop

		vlcBitmap = new VlcBitmap();

		vlcBitmap.set_height(FlxG.stage.stageHeight);
		vlcBitmap.set_width(FlxG.stage.stageHeight * (16 / 9));

		vlcBitmap.onVideoReady = onVLCVideoReady;
		vlcBitmap.onComplete = onVLCComplete;
		vlcBitmap.onError = onVLCError;

		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);

		if (repeat)
			vlcBitmap.repeat = -1;
		else
			vlcBitmap.repeat = 0;

		vlcBitmap.inWindow = isWindow;
		vlcBitmap.fullscreen = isFullscreen;

		FlxG.addChildBelowMouse(vlcBitmap);

		vlcBitmap.play(checkFile(path));

		if (outputTo != null)
		{
			vlcBitmap.alpha = 0;
			sprite = outputTo;
		}

		#end
	}

	#if desktop

	function checkFile(fileName:String):String
	{
		var pDir = "";
		var appDir = "file:///" + Sys.getCwd() + "/";

		if (fileName.indexOf(":") == -1)
			pDir = appDir;
		else if (fileName.indexOf("file://") == -1 || fileName.indexOf("http") == -1)
			pDir = "file:///";

		return pDir + fileName;
	}

	function onVLCVideoReady()
	{
		if (sprite != null)
			sprite.loadGraphic(vlcBitmap.bitmapData);
	}

	public function onVLCComplete()
	{
		vlcBitmap.stop();

		FlxG.camera.fade(FlxColor.BLACK, 0, false);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			if (finishCallback != null)
				LoadingState.loadAndSwitchState(finishCallback);

			vlcBitmap.dispose();

			if (FlxG.game.contains(vlcBitmap))
				FlxG.game.removeChild(vlcBitmap);
		});
	}

	function onVLCError()
	{
		if (finishCallback != null)
			LoadingState.loadAndSwitchState(finishCallback);
	}

	function update(e:Event)
	{
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
		{
			if (vlcBitmap.isPlaying)
				onVLCComplete();
		}

		vlcBitmap.volume = FlxG.sound.volume + 0.3;

		if (FlxG.sound.volume <= 0.1)
			vlcBitmap.volume = 0;
	}

	#end

	function client_onMetaData(path:Dynamic)
	{
		video.attachNetStream(netStream);

		video.width = FlxG.width;
		video.height = FlxG.height;
	}

	function netConnection_onNetStatus(path:Dynamic)
	{
		if (path.info.code == "NetStream.Play.Complete")
			finishVideo();
	}

	function finishVideo()
	{
		#if html5

		if (netStream != null)
			netStream.dispose();

		if (video != null && FlxG.game.contains(video))
			FlxG.game.removeChild(video);

		#end

		if (finishCallback != null)
			LoadingState.loadAndSwitchState(finishCallback);
		else
			LoadingState.loadAndSwitchState(new MainMenuState());
	}
}