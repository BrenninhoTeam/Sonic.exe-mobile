package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import flixel.FlxG;

#if desktop
import vlc.VlcBitmap;
#end

class WebmPlayer extends Sprite
{
	public var isPlaying:Bool  = false;
	public var paused:Bool     = false;
	public var repeat:Int      = 0;

	public var onComplete:Void->Void = null;
	public var onError:String->Void  = null;

	public var bitmapData(default, null):Dynamic;

	#if desktop
	private var vlcBitmap:VlcBitmap;
	#elseif mobile
	private var video:Video;
	private var netStream:NetStream;
	private var netConnection:NetConnection;
	#end

	private var _repeatCount:Int  = 0;
	private var _sourcePath:String = "";

	public function new()
	{
		super();
		visible = false;
	}

	// ---------------------------------------------------------------
	//  Playback
	// ---------------------------------------------------------------

	public function source(path:String):Void
	{
		_sourcePath = path;
		_repeatCount = 0;
		_setupPlayer(path);
	}

	private function _setupPlayer(path:String):Void
	{
		#if desktop

		if (vlcBitmap == null)
		{
			vlcBitmap = new VlcBitmap();
			vlcBitmap.onEndReached = _onEndReached;
			vlcBitmap.onEncounteredError = _onVlcError;
			addChild(vlcBitmap);
		}

		vlcBitmap.set_width(FlxG.width);
		vlcBitmap.set_height(FlxG.height);
		vlcBitmap.play(_buildFilePath(path));

		bitmapData = vlcBitmap.bitmapData;
		isPlaying  = true;
		visible    = true;

		#elseif mobile

		_destroyMobile();

		video = new Video(FlxG.width, FlxG.height);
		addChild(video);

		netConnection = new NetConnection();
		netConnection.addEventListener(NetStatusEvent.NET_STATUS, _onNetStatus);
		netConnection.connect(null);

		netStream = new NetStream(netConnection);
		netStream.addEventListener(NetStatusEvent.NET_STATUS, _onNetStatus);
		netStream.client = {
			onMetaData:  function(meta:Dynamic) {},
			onPlayStatus: function(info:Dynamic) {}
		};

		video.attachNetStream(netStream);
		netStream.play(path);

		isPlaying = true;
		visible   = true;

		#end
	}

	public function makePlayer():Void
	{
		visible = true;
	}

	public function pause():Void
	{
		if (!isPlaying || paused)
			return;

		#if desktop
		if (vlcBitmap != null)
			vlcBitmap.pause();
		#elseif mobile
		if (netStream != null)
			netStream.pause();
		#end

		paused = true;
	}

	public function resume():Void
	{
		if (!isPlaying || !paused)
			return;

		#if desktop
		if (vlcBitmap != null)
			vlcBitmap.resume();
		#elseif mobile
		if (netStream != null)
			netStream.resume();
		#end

		paused = false;
	}

	public function togglePause():Void
	{
		if (paused) resume() else pause();
	}

	public function stop():Void
	{
		#if desktop
		if (vlcBitmap != null)
			vlcBitmap.stop();
		#elseif mobile
		_destroyMobile();
		#end

		isPlaying = false;
		paused    = false;
		visible   = false;
	}

	public function resize(width:Float, height:Float):Void
	{
		#if desktop
		if (vlcBitmap != null)
		{
			vlcBitmap.set_width(Std.int(width));
			vlcBitmap.set_height(Std.int(height));
		}
		#elseif mobile
		if (video != null)
		{
			video.width  = width;
			video.height = height;
		}
		#end
	}

	public function destroy():Void
	{
		stop();

		#if desktop
		if (vlcBitmap != null)
		{
			if (contains(vlcBitmap))
				removeChild(vlcBitmap);
			vlcBitmap = null;
		}
		#elseif mobile
		_destroyMobile();
		#end

		onComplete  = null;
		onError     = null;
		bitmapData  = null;
	}

	// ---------------------------------------------------------------
	//  Internal helpers
	// ---------------------------------------------------------------

	#if mobile
	private function _destroyMobile():Void
	{
		if (netStream != null)
		{
			netStream.close();
			netStream = null;
		}

		if (netConnection != null)
		{
			netConnection.removeEventListener(NetStatusEvent.NET_STATUS, _onNetStatus);
			netConnection.close();
			netConnection = null;
		}

		if (video != null)
		{
			if (contains(video))
				removeChild(video);
			video.clear();
			video = null;
		}
	}

	private function _onNetStatus(e:NetStatusEvent):Void
	{
		switch (e.info.code)
		{
			case "NetStream.Play.StreamNotFound":
				if (onError != null)
					onError('Stream not found: $_sourcePath');

			case "NetStream.Play.Complete":
				_onEndReached();
		}
	}
	#end

	private function _onEndReached():Void
	{
		if (repeat < 0 || _repeatCount < repeat)
		{
			_repeatCount++;
			_setupPlayer(_sourcePath);
			return;
		}

		isPlaying = false;
		visible   = false;

		if (onComplete != null)
			onComplete();
	}

	#if desktop
	private function _onVlcError():Void
	{
		isPlaying = false;
		if (onError != null)
			onError('VLC failed to play: $_sourcePath');
	}
	#end

	private function _buildFilePath(fileName:String):String
	{
		#if desktop

		if (fileName.startsWith("http://") || fileName.startsWith("https://") || fileName.startsWith("file:///"))
			return fileName;

		if (fileName.indexOf(":") != -1)
			return "file:///" + fileName;

		return "file:///" + Sys.getCwd() + "/" + fileName;

		#else

		return fileName;

		#end
	}
}
