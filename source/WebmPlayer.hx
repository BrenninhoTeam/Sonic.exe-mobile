package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import flixel.FlxG;

#if desktop
import vlc.VlcBitmap;
#end

class WebmPlayer extends Sprite
{
	public var isPlaying:Bool = false;
	public var paused:Bool = false;
	public var repeat:Int = 0;
	public var bitmapData(default, null):Dynamic;

	#if desktop
	public var vlcBitmap:VlcBitmap;
	#end

	#if mobile
	public var video:Video;
	public var netStream:NetStream;
	public var netConnection:NetConnection;
	#end

	public function new()
	{
		super();
	}

	public function source(path:String):Void
	{
		#if desktop

		vlcBitmap = new VlcBitmap();
		vlcBitmap.set_width(FlxG.width);
		vlcBitmap.set_height(FlxG.height);

		addChild(vlcBitmap);

		vlcBitmap.play(checkFile(path));

		bitmapData = vlcBitmap.bitmapData;
		isPlaying = true;

		#elif mobile

		video = new Video();
		video.width = FlxG.width;
		video.height = FlxG.height;

		addChild(video);

		netConnection = new NetConnection();
		netConnection.connect(null);

		netStream = new NetStream(netConnection);

		netStream.client =
		{
			onMetaData: function(meta:Dynamic) {}
		};

		video.attachNetStream(netStream);
		netStream.play(path);

		isPlaying = true;

		#end
	}

	public function makePlayer():Void
	{
		visible = true;
	}

	public function pause():Void
	{
		#if desktop

		if (vlcBitmap != null)
			vlcBitmap.pause();

		#elif mobile

		if (netStream != null)
			netStream.pause();

		#end

		paused = true;
	}

	public function resume():Void
	{
		#if desktop

		if (vlcBitmap != null)
			vlcBitmap.resume();

		#elif mobile

		if (netStream != null)
			netStream.resume();

		#end

		paused = false;
	}

	public function stop():Void
	{
		#if desktop

		if (vlcBitmap != null)
			vlcBitmap.stop();

		#elif mobile

		if (netStream != null)
			netStream.close();

		#end

		isPlaying = false;
	}

	function checkFile(fileName:String):String
	{
		#if desktop

		var pDir = "";
		var appDir = "file:///" + Sys.getCwd() + "/";

		if (fileName.indexOf(":") == -1)
			pDir = appDir;
		else if (fileName.indexOf("file://") == -1 || fileName.indexOf("http") == -1)
			pDir = "file:///";

		return pDir + fileName;

		#else

		return fileName;

		#end
	}
}