package entities;

import com.haxepunk.Entity;
import com.haxepunk.graphics.Tilemap;
import com.haxepunk.Scene;
import com.haxepunk.HXP;
import com.haxepunk.tmx.TmxMap;
import com.haxepunk.tmx.TmxEntity;

import plugins.tiled.TiledXML;
import plugins.tiled.TiledLayer;
import plugins.tiled.TiledTileSet;
import plugins.tiled.TiledPropertySet;
import plugins.animatedTilemap.AnimatedTilemap;

import GNavigation;
import GameScene;

/**
 * ...
 * @author Boarnoah
 */
class GMap extends Entity{
	public var mapWidth:Int = 0;
	public var mapHeight:Int = 0;
	
	public var gameMapData:TmxMap;
	public var gameMap:TmxEntity;
	public var tiledMap:TiledXML;

	private var gameNav:GNavigation;
	
	public var tileMapList:Array<AnimatedTilemap>;
	
	public function new() {
		super();
	}
	
	dynamic public function begin(){
		gameNav = cast(scene, GameScene).gameNav;
	}
	
	dynamic public function loadMap(mapName:String) {
		gameNav = cast(scene, GameScene).gameNav;
		
		tileMapList = new Array<AnimatedTilemap>();
		
		trace("Loading map: \"" + mapName + "\"...");
		
		HXP.timeFlag();
			gameMapData = TmxMap.loadFromFile(mapName);
		trace("HaxepunkTmx parse: " + (HXP.timeFlag()*1000) + " ms");
		
		HXP.timeFlag();
			tiledMap = TiledXML.loadFromFile(mapName);
		trace("TiledXML parse: " + (HXP.timeFlag() * 1000) + " ms");
		
		mapWidth = tiledMap.width;
		mapHeight = tiledMap.height;

		loadTerrain();
		//loadNav();
		//loadObjects();	
	}
	
	private function loadTerrain() {
		/**
		 * Base (water) Layer = 0
		 * Ground Layer = 1
		 * 
		 * Pointless to make it too generic (figure out tileSet dynamically) 
		 * since the tileSets are known to begin with etc...
		 */
		
		for(index in 0...2){
			loadLayer(index);
			loadAnimations(index);
			addGraphic(tileMapList[index]);
		}
	}
	
	private function loadLayer(index:Int) {	
		var animTileMap:AnimatedTilemap = new AnimatedTilemap("graphics/tileSet1.png", (mapWidth * Main.tW), (mapHeight * Main.tH), Main.tW, Main.tH, 1, 1, true);
		var tiledLayer:TiledLayer = tiledMap.tileLayers[index];
		var tileSet:TiledTileSet = tiledMap.tileSets[0];
		
		var tileIndex:Int = 0;
		
		animTileMap.smooth = false;
		
		for(c in 0...mapWidth){
			for (r in 0...mapHeight) {
				
				var tileGid:Int = tiledLayer.tileData[tileIndex];
				
				// 0 denotes no tile
				if (tileGid != 0) {
					var tileSetIndex:Int = tiledMap.findTileSet(tileGid);
					tileSet = tiledMap.tileSets[tileSetIndex];
					
					var anim:Int = Std.parseInt(tileSet.getTileProperty(tileGid, "anim"));
					var tileCost:String = tileSet.getTileProperty(tileGid, "moveCost");
					var tileType:String = tileSet.getTileProperty(tileGid, "tileType");
					
					gameNav.addTile(Std.parseInt(tileCost));
					animTileMap.setTile(r, c, (tileGid - tileSet.firstGid));
				}else {
					gameNav.addTile(-1);
					animTileMap.setTile(r, c, -1);
				}
				tileIndex++;
			}
		}
		
		tileMapList.push(animTileMap);
	}
	
	private function loadAnimations(index:Int) {
		var tileSet:TiledTileSet = tiledMap.tileSets[0];
		var firstGid:Int = tileSet.firstGid;
		var numTiles:Int = tileSet.tileProps.length;
		
		// This not numRow * numCol because tileId (index on sheet) is independent
		// of which tiles have properties (and therefore appear in our list)
		// tl;dr to stop breaking on empty tiles
		
		var animTileMap:AnimatedTilemap = tileMapList[index];
		
		for (i in 0...numTiles) {
			if(tileSet.tileProps[i] != null){
				var anim:Int = Std.parseInt(tileSet.tileProps[i].resolve("anim"));
				
				if (anim == 1) {
					var fLength:Int = Std.parseInt(tileSet.tileProps[i].resolve("fLength"));
					var fps:Int = Std.parseInt(tileSet.tileProps[i].resolve("fps"));
					
					var frameArray:Array<Int> = new Array<Int>();
					
					for(f in 0...fLength)
						frameArray.push(i + f);
					
					animTileMap.animate(frameArray, fps);
				}
			}
		}
	}
	
	private function loadObjects(){
		for (object in gameMapData.getObjectGroup("oLayer1").objects) {
			var _x:Int = object.x;
			var _y:Int = object.y;
			var _type:String = object.type;
				
			/**
			 * ge = GameEntity
			 * f = faction
			 * ut = unitType
			 **/
			
			if (_type == "ge") {
				var _unitType:Int = Std.parseInt(object.custom.resolve("ut"));
				var _faction:Int = Std.parseInt(object.custom.resolve("f"));
				scene.add(new GameEntity(_x, _y, _unitType, _faction));
			}
		}
	}
	
	dynamic public function getObjects(oLayer:String) {
		return gameMapData.getObjectGroup(oLayer).objects;
	}
	
	dynamic public function getMapSize() {
		return gameMapData.width;
	}
}

	// Graphics 
	/*
	if (anim == 0) {
		
		//staticTileMap.setTile(r, c, (tileGid - tileSet.firstGid));
	}else {
		var fLength:Int = Std.parseInt(tileSet.getTileProperty(tileGid, "fLength"));
		var fps:Int = Std.parseInt(tileSet.getTileProperty(tileGid, "fps"));
		animTileMap.setTile(r, c, (tileGid - tileSet.firstGid));
		//animTileMap.setTile(r, c, 0);
	}
	*/