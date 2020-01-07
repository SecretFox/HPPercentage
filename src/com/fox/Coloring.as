import com.Utils.Colors;
/**
 * ...
 * @author fox
 */
class com.fox.Coloring {
	/*
	* https://www.cssmatic.com/gradient-generator#'\-moz\-linear\-gradient\%28left\%2C\%20rgba\%2832\%2C255\%2C140\%2C1\%29\%200\%25\%2C\%20rgba\%28124\%2C240\%2C101\%2C1\%29\%2025\%25\%2C\%20rgba\%28234\%2C240\%2C48\%2C1\%29\%2050\%25\%2C\%20rgba\%28240\%2C109\%2C48\%2C1\%29\%2075\%25\%2C\%20rgba\%28207\%2C4\%2C4\%2C1\%29\%20100\%25\%29\%3B'
	* https://www.cssmatic.com/gradient-generator#'\-moz\-linear\-gradient\%28left\%2C\%20rgba\%2832\%2C255\%2C140\%2C1\%29\%200\%25\%2C\%20rgba\%28213\%2C235\%2C47\%2C1\%29\%2033\%25\%2C\%20rgba\%28240\%2C61\%2C48\%2C1\%29\%2066\%25\%2C\%20rgba\%28207\%2C4\%2C4\%2C1\%29\%20100\%25\%29\%3B'
	* red -> orange -> yellow ->green
	*/
	static var ColorArray:Array = [[207, 4, 4], [240, 61, 48], [213, 235, 47], [32, 255, 140]]; // HP Based
	static var HexArray:Array = [0xcf0404,  0xe6db10,  0x20ff8c]; // gradient HP Bar

	public function Coloring() {}
	
	// Finds color between two ColorArray values, based on the enemy HP
	static function GetColor(hp) {
		if (hp == 1) return 0x20FF8A;
		else if (hp == 0) return 0xff4646;
		else if (!hp) return;
		var segments = hp * (ColorArray.length-1);
		var colorIndex = Math.floor(segments);
		var highPercent = segments - colorIndex;
		var lowPercent = 1 - highPercent;
		var intColor = 	(ColorArray[colorIndex][0] * (lowPercent) + ColorArray[colorIndex + 1][0] * highPercent) << 16 |
						(ColorArray[colorIndex][1] * (lowPercent) + ColorArray[colorIndex + 1][1] * highPercent) << 8 |
						(ColorArray[colorIndex][2] * (lowPercent) + ColorArray[colorIndex + 1][2] * highPercent);
		// no need to convert to Hex
		return intColor;
	}
	
	static function DrawDivider(clip:MovieClip, sizeclip:MovieClip, amount, custom){
		var y = sizeclip._y+1;
		var width = sizeclip.width;
		var height = sizeclip.height-3;
		for (var i = 1; i < amount; i++) {
			clip.moveTo(width / amount * i, y);
			clip.lineStyle(1, 0x000000, 100);
			clip.lineTo(width / amount * i, y + height);
		}
		if (custom){
			var customs:Array = string(custom).split(",");
			for (var i = 0; i < customs.length; i++){
				clip.moveTo(width / 100 * customs[i], y);
				clip.lineStyle(1, 0x000000, 100);
				clip.lineTo(width / 100 * customs[i], y + height);
			}
		}
	}

	static function DrawSolid(clip:MovieClip, color) {
		var x = clip._parent._x-1;
		var y = clip._parent._y;
		var width = clip._parent.width;
		var height = clip._parent.height;

		clip.clear();
		clip.moveTo(x, y);
		clip.beginFill(color, 100);
		clip.lineStyle(1, 0x000000, 0);
		clip.lineTo(x + width, y);
		clip.lineTo(x + width, y + height);
		clip.lineTo(x, y + height);
		clip.lineTo(x, y);
		clip.endFill();
	}
	
	static function Recolor(clip:MovieClip, color:Number){
		Colors.ApplyColor(clip, color);
	}
	
	static function setClippingMask(clip:MovieClip, hp:Number){
		clip.setMask(null); //crashes without
		var mask:MovieClip = com.GameInterface.ProjectUtils.SetMovieClipMask(clip, clip._parent, clip._parent.height+2, clip._parent.width * hp);
	}
	
	// https://as2tutorials.wordpress.com/2010/03/04/using-gradients-in-flash-as2/
	// Draws gradient from each HexArray entry to the next.
	static function DrawGradient(clip:MovieClip) {
		var x = clip._x;
		var y = clip._y;
		var gradientWidth = clip._parent.width / (HexArray.length-1);
		var height = clip._parent.height;

		var fillType = "linear";
		var alphas = [100, 100];
		var ratios = [0, 255];
		var segments = HexArray.length - 1;
		//gradient
		for (var i:Number = 0; i < segments; i++) {
			var colors = [HexArray[i], HexArray[i+1]];
			var matrix = {matrixType:"box", x:x, y:y-1, w:gradientWidth+1, h:height+2, r:0 / 180 * Math.PI};
			clip.moveTo(x, y);
			clip.lineStyle(1, 0x000000, 0);
			clip.beginGradientFill(fillType, colors, alphas, ratios, matrix);
			clip.lineTo(x + gradientWidth, y);
			clip.lineTo(x + gradientWidth, y + height);
			clip.lineTo(x, y + height);
			clip.lineTo(x, y);
			clip.endFill();
			x += gradientWidth;
		}
	}
}