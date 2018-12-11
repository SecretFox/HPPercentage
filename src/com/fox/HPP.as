/*
* ...
* @author fox
*/
import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.fox.Coloring;
import mx.utils.Delegate;

class com.fox.HPP {
	private var mode:DistributedValue;
	private var decimals:DistributedValue;
	private var colormode:DistributedValue;

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
	}
	public function Load() {
		Hook();
		colormode.SignalChanged.Connect(ChangeColormode, this);
	}
	public function Unload() {
		colormode.SignalChanged.Disconnect(ChangeColormode, this);
	}
	public function Activate(config:Archive) {
		mode.SetValue(config.FindEntry("Mode", 3));
		decimals.SetValue(config.FindEntry("Decimal", 0));
		colormode.SetValue(config.FindEntry("Color", 1));
	}
	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("Mode", mode.GetValue());
		config.AddEntry("Color", colormode.GetValue());
		config.AddEntry("Decimal", decimals.GetValue());
		return config
	}
	private function ChangeColormode(dv:DistributedValue) {
		// we can keep m_Overlay clip
		// Graphics will be redrawn on next update
		_root.playerinfo.m_HealthBar.m_Bar.m_Overlay.mask.removeMovieClip();
		_root.targetinfo.m_HealthBar.m_Bar.m_Overlay.mask.removeMovieClip();
		
		_root.playerinfo.m_HealthBar.m_Bar.m_Overlay.m_Graphics.removeMovieClip();
		_root.targetinfo.m_HealthBar.m_Bar.m_Overlay.m_Graphics.removeMovieClip();

		_root.playerinfo.m_HealthBar.UpdateStatBar();
		_root.targetinfo.m_HealthBar.UpdateStatBar();
	}

	public function Hook() {
		//Check that nametag component is loaded
		var healthbarComp = _global.com.Components.HealthBar;
		if (!healthbarComp) {
			setTimeout(Delegate.create(this, Hook), 100);
			return
		}
		//Only hook once
		if (_global.com.fox.HPPHook) return;
		_global.com.fox.HPPHook = true;

		//Update HP text
		var f:Function = function ():Void {
			if (com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode") == 1) {
				arguments.callee.base.apply(this, arguments);
			}else{
				var hp = 100 * this.m_Current / this.m_Max;
				if (this.m_ShowText && hp >= 0) {
					if (hp > 100) hp = 100;
					if (com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode") == 2) {
						var multi = Math.pow(10, com.GameInterface.DistributedValueBase.GetDValue("HPP_Decimals"));
						var percentage =  Math.round(hp * multi) / multi;
						this.m_Text.htmlText = percentage + " %";
					} else if (com.GameInterface.DistributedValueBase.GetDValue("HPP_Mode") == 3) {
						var number = Math.floor(this.m_Current) + " / " + Math.floor(this.m_Max);
						var multi = Math.pow(10, com.GameInterface.DistributedValueBase.GetDValue("HPP_Decimals"));
						var percentage =  Math.round(hp * multi) / multi;
						this.m_Text.htmlText = number + "    " + percentage + " %";
					}
				}
			}
		}
		f.base = healthbarComp.prototype.UpdateStatText;
		healthbarComp.prototype.UpdateStatText = f;

		//Update HP bar
		f = function (snap:Boolean):Void {
			if (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 1 || !this.m_Bar.m_Overlay){
				arguments.callee.base.apply(this, arguments);
			}else{
				if ( this.m_Current == undefined || this.m_Max == undefined )	{
					this.Hide();
				}else{
					this.Show();
					this.m_Bar.m_Boost._width = 0;
					this.m_Bar.m_OverlayEnemy._xscale = 100;
					this.m_Bar.m_OverlayFriend._xscale = 100;
					var hp = this.m_Current / this.m_Max;
					// HP based
					// need to recolor on each update.
					// HP dividers are on separate clip so that i dont need to touch them again
					if (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 2) {
						var color = Coloring.GetColor(hp);
						if (color){
							if (!this.m_Bar.m_Overlay.m_Graphics.m_Color){
								var m_Graphics:MovieClip = this.m_Bar.m_Overlay.createEmptyMovieClip("m_Graphics", this.m_Bar.m_Overlay.getNextHighestDepth());
								var m_Color = m_Graphics.createEmptyMovieClip("m_Color", m_Graphics.getNextHighestDepth());
								var m_Segment = m_Graphics.createEmptyMovieClip("m_Segment", m_Graphics.getNextHighestDepth());
								Coloring.DrawSolid(m_Color, color);
								Coloring.DrawSegment(m_Segment);
							}else{
								Coloring.setClippingMask(this.m_Bar.m_Overlay.m_Graphics, this.m_Bar.m_Overlay, hp);
								Coloring.Recolor(this.m_Bar.m_Overlay.m_Graphics.m_Color, color);
							}
						}
					}
					// Gradient
					// This one stays the same,we just need to adjust clipping mask
					if (com.GameInterface.DistributedValueBase.GetDValue("HPP_ColorMode") == 3) {
						if (!this.m_Bar.m_Overlay.m_Graphics){
							var m_Graphics:MovieClip = this.m_Bar.m_Overlay.createEmptyMovieClip("m_Graphics", this.m_Bar.m_Overlay.getNextHighestDepth());
							Coloring.DrawGradient(m_Graphics);
						}
						Coloring.setClippingMask(this.m_Bar.m_Overlay.m_Graphics, this.m_Bar.m_Overlay, hp);
					}
				}
			}
		}
		f.base = healthbarComp.prototype.UpdateStatBar;
		healthbarComp.prototype.UpdateStatBar = f;

		// Create overlay
		f = function (xscale:Number, yscale:Number, textScale:Number):Void {
			arguments.callee.base.apply(this, arguments);
			if (!this.m_Bar.m_Overlay && xscale == 100) {
				var m_Overlay:MovieClip = this.m_Bar.createEmptyMovieClip("m_Overlay", this.m_Bar.getNextHighestDepth());
				m_Overlay._x = this.m_Bar.m_MeterFriend._x;
				m_Overlay._y = this.m_Bar.m_MeterFriend._y-2;
				m_Overlay.width = this.m_Bar.m_MeterFriend._width;
				m_Overlay.height = this.m_Bar.m_MeterFriend._height;
				this.UpdateStatBar();
			}
		}
		f.base = healthbarComp.prototype.SetBarScale;
		healthbarComp.prototype.SetBarScale = f;

		_root.playerinfo.m_HealthBar.SetBarScale(100, 85, 70, 100);
		_root.targetinfo.m_HealthBar.SetBarScale(100, 85, 70, 100);
		_root.playerinfo.m_HealthBar.UpdateStatText();
	}
}