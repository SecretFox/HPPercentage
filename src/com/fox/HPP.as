/*
* ...
* @author fox
*/
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.CharacterBase;
import com.Utils.Archive;
import com.fox.Coloring;
import mx.utils.Delegate;

class com.fox.HPP {
	private var mode:DistributedValue;
	private var decimals:DistributedValue;
	private var colormode:DistributedValue;
	private var divider:DistributedValue;
	private var divider_custom:DistributedValue;

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
		divider = DistributedValue.Create("HPP_Segments");
		divider_custom = DistributedValue.Create("HPP_Segments_Custom");
	}
	public function Load() {
		Hook();
		colormode.SignalChanged.Connect(settingChanged, this);
		mode.SignalChanged.Connect(settingChanged, this);
		divider.SignalChanged.Connect(settingChanged, this);
		divider_custom.SignalChanged.Connect(settingChanged, this);
	}
	public function Unload() {
		colormode.SignalChanged.Disconnect(settingChanged, this);
		mode.SignalChanged.Disconnect(settingChanged, this);
		divider.SignalChanged.Disconnect(settingChanged, this);
		divider_custom.SignalChanged.Connect(settingChanged, this);
	}
	public function Activate(config:Archive) {
		mode.SetValue(config.FindEntry("Mode", 3));
		decimals.SetValue(config.FindEntry("Decimal", 0));
		colormode.SetValue(config.FindEntry("Color", 1));
		divider.SetValue(config.FindEntry("Dividers", 4));
		divider_custom.SetValue(config.FindEntry("Custom", false));
		Draw();
	}
	
	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("Mode", mode.GetValue());
		config.AddEntry("Color", colormode.GetValue());
		config.AddEntry("Decimal", decimals.GetValue());
		config.AddEntry("Dividers", divider.GetValue());
		config.AddEntry("Custom", divider_custom.GetValue());
		return config
	}
	
	private function Draw(force){
		if (!_root.playerinfo.health.reDraw){
			setTimeout(Delegate.create(this, Draw), 100, force);
			return;
		}
		_root.playerinfo.health.reDraw(force);
		_root.targetinfo.health.reDraw(force);
	}
	private function settingChanged() {
		Draw(true);
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
		
		// function for initializing graphic container(and clearing it)
		var f:Function = function ():Void {
			//needed variables
			this.isPlayer = this.m_Dynel.GetID().Equal(CharacterBase.GetClientCharID());
			this.colorMode = com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode");
			this.numMode = com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode");
			this.decimals =  com.GameInterface.DistributedValueBase.GetDValue("HPP_Decimals");
			if (!this.m_Bar.m_Overlay){
				//hide default border
				this.m_Bar.m_ArtworkFriend._visible = false;
				this.m_Bar.m_ArtworkEnemy._visible = false;
				// Make default bars thicc (looks better with outline)
				this.m_Bar.m_MeterFriend._height = 
					this.m_Bar.m_MeterEnemy._height = 
					this.m_Bar.m_OverlayEnemy._height = 
					this.m_Bar.m_OverlayFriend._height = 16;
				this.m_Bar.m_MeterFriend._y = 
					this.m_Bar.m_MeterEnemy._y =
					this.m_Bar.m_OverlayEnemy._y =
					this.m_Bar.m_OverlayFriend._y = -1;
			}else{
				/* 
				* m_Overlay swaps depths with barrier later, giving it a negative depth
				* movieclips with negative depths cannot be removed
				*/
				if (this.m_Bar.m_Overlay.getDepth() < this.m_Bar.m_Boost.getDepth() && this.m_Bar.m_Boost.getDepth() > 0){
					this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_Boost);
				}else{
					this.m_Bar.m_Overlay.swapDepths(999);
				}
				this.m_Bar.m_Overlay.removeMovieClip();
			}
			//base
			var m_Overlay = this.m_Bar.createEmptyMovieClip("m_Overlay", this.m_Bar.getNextHighestDepth());
			//Store info for sizing
			m_Overlay._y = this.m_Bar.m_ArtworkEnemy._y - 2;
			m_Overlay.y = this.m_Bar.m_ArtworkEnemy._y;
			m_Overlay.x = this.m_Bar.m_ArtworkEnemy._x-1;
			m_Overlay.width = this.m_Bar.m_ArtworkEnemy._width + 1;
			m_Overlay.height = this.m_Bar.m_ArtworkEnemy._height - 1;
			//components
			m_Overlay.createEmptyMovieClip("m_Graphics", m_Overlay.getNextHighestDepth());
			m_Overlay.createEmptyMovieClip("m_Divider", m_Overlay.getNextHighestDepth());
			m_Overlay.createEmptyMovieClip("m_Border", m_Overlay.getNextHighestDepth());
		}
		HealthBar.prototype.InitContainer = f;

		// Creating dividers
		f = function ():Void {
			var dividers = com.GameInterface.DistributedValueBase.GetDValue("HPP_Segments");
			var custom:String = undefined;
			if (this.isPlayer){
				custom = com.GameInterface.DistributedValueBase.GetDValue("HPP_Segments_Custom");
			}
			if (dividers || custom) {
				Coloring.DrawDivider(this.m_Bar.m_Overlay.m_Divider, dividers, custom);
			}
			Coloring.DrawBox(this.m_Bar.m_Overlay.m_Border, this.m_Bar.m_ArtworkFriend);
			
		}
		HealthBar.prototype.DrawDividers = f;
		
		// redrawing graphics, called when changing settings
		f = function (force):Void {
			if (force || !this.m_Bar.m_Overlay){
				this.InitContainer();
				this.DrawHealthBar();
				this.DrawDividers();
				this.UpdateStatText();
				if (this.colorMode == 2 || this.colorMode == 3) {
					this.m_Bar.m_MeterEnemy._alpha = 0;
					this.m_Bar.m_MeterFriend._alpha = 0;
				}
				else{
					if (this.isPlayer){
						this.m_Bar.m_MeterFriend._alpha = 100;
					}else{
						this.m_Bar.m_MeterEnemy._alpha = 100;
					}
				}
			}
		}
		HealthBar.prototype.reDraw = f;
		// Drawing graphics
		f = function ():Void {
			if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_Boost.getDepth()){
				this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_Boost);
			}
			if (this.colorMode == 2) {
				var color = Coloring.GetColor(1);
				Coloring.DrawSolid(this.m_Bar.m_Overlay.m_Graphics, color);
			}
			else if (this.colorMode == 3) {
				Coloring.DrawGradient(this.m_Bar.m_Overlay.m_Graphics);
			}
			this.UpdateStatBar();
		}
		HealthBar.prototype.DrawHealthBar = f;
		
		
		// Extend update HP text function to display health as percentage
		f = function ():Void {
			if (!this.m_ShowText) return;
			if ( this.numMode == 1) {
				arguments.callee.base.apply(this, arguments);
			}else{
				var hp = 100 * this.m_Current / this.m_Max;
				if (hp >= 0) {
					if (hp > 100) hp = 100;
					var multi = Math.pow(10, this.decimals);
					var percentage =  Math.round(hp * multi) / multi;
					if (this.numMode == 2) {
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

		// Extend update HP bar function to update HP bar color
		// Original function still has to draw the barrier first
		// TODO Aegis?
		f = function (snap:Boolean):Void {
			arguments.callee.base.apply(this, arguments);
			if (this.m_Bar.m_Overlay && (this.colorMode == 2 || this.colorMode == 3)){
				var hp = this.m_Current / this.m_Max;
				if (isNaN(hp)) hp = 0;
				// HP based
				// need to recolor on each update.
				if (this.colorMode == 2) {
					// skip color calculation if difference is less than 5%
					if (!this.m_Bar.m_Overlay.last || Math.abs(this.m_Bar.m_Overlay.last - hp) > 0.05){
						this.m_Bar.m_Overlay.last = hp;
						var color = Coloring.GetColor(hp);
						if (color){
							Coloring.Recolor(this.m_Bar.m_Overlay.m_Graphics, color);
						}
					}
				}
				//gradient only needs clipping mode adjustment
				Coloring.setClippingMask(this.m_Bar.m_Overlay.m_Graphics, hp);
			}
		}
		f.base = HealthBar.prototype.UpdateStatBar;
		HealthBar.prototype.UpdateStatBar = f;
	}
}