/*
* ...
* @author fox
*/
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Dynel;
import com.Utils.Archive;
import com.fox.Coloring;
import mx.utils.Delegate;

class com.fox.HPP {
	private var mode:DistributedValue;
	private var decimals:DistributedValue;
	private var colormode:DistributedValue;
	private var divider:DistributedValue;

	public static function main(swfRoot:MovieClip):Void	{
		var s_app = new HPP(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config) {s_app.Activate(config)};
		swfRoot.OnModuleDeactivated = function() {return s_app.Deactivate()};
	}
	public function HPP() {
		mode = DistributedValue.Create("HPP_Mode");
		decimals = DistributedValue.Create("HPP_Decimals");
		colormode = DistributedValue.Create("HPP_ColorMode");
		divider = DistributedValue.Create("HPP_Dividers");
	}
	public function Load() {
		Hook();
		colormode.SignalChanged.Connect(settingChanged, this);
		mode.SignalChanged.Connect(settingChanged, this);
		divider.SignalChanged.Connect(settingChanged, this);
	}
	public function Unload() {
		colormode.SignalChanged.Disconnect(settingChanged, this);
		mode.SignalChanged.Disconnect(settingChanged, this);
		divider.SignalChanged.Disconnect(settingChanged, this);
	}
	public function Activate(config:Archive) {
		mode.SetValue(config.FindEntry("Mode", 3));
		decimals.SetValue(config.FindEntry("Decimal", 0));
		colormode.SetValue(config.FindEntry("Color", 1));
		divider.SetValue(config.FindEntry("Dividers", 4));
		settingChanged();
	}
	
	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("Mode", mode.GetValue());
		config.AddEntry("Color", colormode.GetValue());
		config.AddEntry("Decimal", decimals.GetValue());
		config.AddEntry("Dividers", divider.GetValue());
		return config
	}
	private function settingChanged() {
		if (!_root.playerinfo.health.reDraw){
			setTimeout(Delegate.create(this, settingChanged), 100);
			return;
		}
		_root.playerinfo.health.reDraw();
		_root.targetinfo.health.reDraw();
	}

	public function Hook() {
		//Only hook once
		if (_global.com.fox.HPPHook) return;
		
		//Check that HealthBar component is loaded
		var HealthBar = _global.com.Components.HealthBar;
		if (!HealthBar) {
			setTimeout(Delegate.create(this, Hook), 100);
			return
		}
		_global.com.fox.HPPHook = true;
		
		// function for initializing our graphic container
		var f:Function = function (scale):Void {
			if (!this.m_Bar.m_Overlay && scale == 100) {
				var m_Overlay:MovieClip = this.m_Bar.createEmptyMovieClip("m_Overlay", this.m_Bar.getNextHighestDepth());
				m_Overlay._x = this.m_Bar.m_ArtworkEnemy._x;
				m_Overlay._y = this.m_Bar.m_ArtworkEnemy._y;
				m_Overlay.width = this.m_Bar.m_ArtworkEnemy._width;
				m_Overlay.height = this.m_Bar.m_ArtworkEnemy._height - 3;
			}
		}
		HealthBar.prototype.InitContainer = f;

		// function for creating dividers for the HP bar
		f = function ():Void {
			var dividers = com.GameInterface.DistributedValueBase.GetDValue("HPP_Dividers");
			if (this.m_Bar._xscale == 100 && dividers) {
				this.m_Bar.m_Divider.removeMovieClip();
				var div = this.m_Bar.createEmptyMovieClip("m_Divider", this.m_Bar.getNextHighestDepth());
				Coloring.DrawDivider(div, this.m_Bar.m_Overlay, dividers);
			}
		}
		HealthBar.prototype.DrawDividers = f;
		
		// function for redrawing our graphics, called when changing settings
		f = function ():Void {
			if (!this.m_Bar.m_Overlay){
				this.InitContainer(this.m_Bar._xscale);
			}
			if (this.m_Bar.m_Overlay){
				if(this.m_Bar.m_Overlay.m_Graphics){
					this.m_Bar.m_Overlay.m_Graphics.setMask(null);
					this.m_Bar.m_Overlay.mask.removeMovieClip();
					this.m_Bar.m_Overlay.m_Graphics.removeMovieClip();
				}
				
				this.DrawDividers();
				this.SetDynel(this.m_Dynel, true);
				this.DrawHealthBar();
			}
		}
		HealthBar.prototype.reDraw = f;
	
		// function for drawing bar overlay
		f = function ():Void {
			// HP based
			if (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 2) {
				var color = Coloring.GetColor(1);
				var graph:MovieClip = this.m_Bar.m_Overlay.createEmptyMovieClip("m_Graphics", this.m_Bar.m_Overlay.getNextHighestDepth());
				// Swap it with artwork(borders), making artwork new top element,followed by our graphics
				if (this.m_IsPlayer){
					if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_ArtworkFriend.getDepth()){
						this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_ArtworkFriend);
					}
				}
				else{
					if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_ArtworkEnemy.getDepth()){
						this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_ArtworkEnemy);
					}
				}
				//Now swap it with barrier
				// result : artwork -> barrier -> our graphic
				if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_Boost.getDepth()){
					this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_Boost);
				}
				Coloring.DrawSolid(graph, color);
			}
			// Gradient
			if (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 3) {
				var m_Graphics:MovieClip = this.m_Bar.m_Overlay.createEmptyMovieClip("m_Graphics", this.m_Bar.m_Overlay.getNextHighestDepth());
				// Swap it with artwork(borders), making artwork new top element, followed by our graphics
				if (this.m_IsPlayer){
					if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_ArtworkFriend.getDepth()){
						this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_ArtworkFriend);
					}
				}
				else{
					if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_ArtworkEnemy.getDepth()){
						this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_ArtworkEnemy);
					}
				}
				//Now swap it with barrier
				// result : artwork -> barrier -> our graphic
				if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_Boost.getDepth()){
					this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_Boost);
				}
				Coloring.DrawGradient(this.m_Bar.m_Overlay.m_Graphics);
			}
		}
		HealthBar.prototype.DrawHealthBar = f;
		
		
		// Extend update HP text function to display health as percentage
		f = function ():Void {
			if (!this.m_ShowText) return;
			if (com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode") == 1) {
				arguments.callee.base.apply(this, arguments);
			}else{
				var hp = 100 * this.m_Current / this.m_Max;
				if (hp >= 0) {
					if (hp > 100) hp = 100;
					var multi = Math.pow(10, com.GameInterface.DistributedValueBase.GetDValue("HPP_Decimals"));
					var percentage =  Math.round(hp * multi) / multi;
					if (com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode") == 2) {
						this.m_Text.htmlText = percentage + " %";
					} else{
						var number = Math.floor(this.m_Current) + " / " + Math.floor(this.m_Max);
						this.m_Text.htmlText = number + "    " + percentage + " %";
					}
				}
			}
		}
		f.base = HealthBar.prototype.UpdateStatText;
		HealthBar.prototype.UpdateStatText = f;

		// Extend update HP bar function to update our HP bar
		// Original function still has to draw the barrier first
		f = function (snap:Boolean):Void {
			arguments.callee.base.apply(this, arguments);
			// If this is HP bar we want to modify
			if (this.m_Bar.m_Overlay && (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 2 || com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 3)){
				var hp = this.m_Current / this.m_Max;
				// HP based
				// need to recolor on each update.
				if (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 2) {
					var color = Coloring.GetColor(hp);
					if (color){
						Coloring.Recolor(this.m_Bar.m_Overlay.m_Graphics, color);
						Coloring.setClippingMask(this.m_Bar.m_Overlay.m_Graphics, hp);
					}
				}
				// Gradient
				// This one stays the same,we just need to adjust clipping mask
				if (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 3) {
					Coloring.setClippingMask(this.m_Bar.m_Overlay.m_Graphics, hp);
				}
			}
		}
		f.base = HealthBar.prototype.UpdateStatBar;
		HealthBar.prototype.UpdateStatBar = f;		
		
		// Extend SetDynel to hide default HP bar if needed
		// default SetDynel also makes them visible again
		f = function (dynel:Dynel):Void {
			arguments.callee.base.apply(this, arguments);
			if (this.m_Bar.m_Overlay && (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 2 || com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 3)) {
				this.m_Bar.m_MeterEnemy._alpha = 0;
				this.m_Bar.m_MeterFriend._alpha = 0;
			}
			// SetMax forces the healthbar to be visible even if player isnt targeting anything
			if (this.m_Dynel.IsEnemy() && com.GameInterface.Game.Character.GetClientCharacter().GetOffensiveTarget().IsNull()){
				this.Hide();
			}
		}
		f.base = HealthBar.prototype.SetDynel;
		HealthBar.prototype.SetDynel = f;
	}
}