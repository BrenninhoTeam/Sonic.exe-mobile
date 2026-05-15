package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Lib;
import openfl.display.FPS;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.FlxG;
import flixel.util.FlxColor;

class Main extends Sprite
{
	var gameWidth:Int = 1280;
	var gameHeight:Int = 720;
	var initialState:Class<FlxState> = TitleState;
	var zoom:Float = -1;
	var framerate:Int = 120;
	var skipSplash:Bool = true;
	var startFullscreen:Bool = false;

	public static var watermarks = true;
	public static var webmHandler:WebmHandler;

	var game:FlxGame;
	var fpsCounter:FPS;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;

			zoom = Math.min(ratioX, ratioY);

			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if cpp
		initialState = Caching;
		#end

		game = new FlxGame(
			gameWidth,
			gameHeight,
			initialState,
			zoom,
			framerate,
			framerate,
			skipSplash,
			startFullscreen
		);

		addChild(game);

		#if web
		var webSource:String = "assets/videos/DO NOT DELETE OR GAME WILL CRASH/dontDelete.webm";

		var vHandler = new VideoHandler();
		vHandler.init1();
		vHandler.video.name = "WEB_VIDEO";
		addChild(vHandler.video);
		vHandler.init2();
		GlobalVideo.setVid(vHandler);
		vHandler.source(webSource);
		#elseif desktop
		var desktopSource:String = "assets/videos/DO NOT DELETE OR GAME WILL CRASH/dontDelete.webm";

		var webmHandle = new WebmHandler();
		webmHandle.source(desktopSource);
		webmHandle.makePlayer();
		webmHandle.webm.name = "WEBM_VIDEO";
		addChild(webmHandle.webm);
		GlobalVideo.setWebm(webmHandle);
		#end

		#if !mobile
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);

		if (FlxG.save.data.fps == null)
			FlxG.save.data.fps = true;

		toggleFPS(FlxG.save.data.fps);
		#end
	}

	public function toggleFPS(fpsEnabled:Bool):Void
	{
		if (fpsCounter != null)
			fpsCounter.visible = fpsEnabled;
	}

	public function changeFPSColor(color:FlxColor):Void
	{
		if (fpsCounter != null)
			fpsCounter.textColor = color;
	}

	public function setFPSCap(cap:Float):Void
	{
		Lib.current.stage.frameRate = cap;
	}

	public function getFPSCap():Float
	{
		return Lib.current.stage.frameRate;
	}

	public function getFPS():Float
	{
		if (fpsCounter != null)
			return fpsCounter.currentFPS;

		return 0;
	}
}