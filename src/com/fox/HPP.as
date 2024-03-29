/*
* ...
* @author fox
*/
import caurina.transitions.Tweener;
import com.GameInterface.AgentSystem;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.BuffData;
import com.GameInterface.Game.CharacterBase;
import com.Utils.Archive;
import com.Utils.Draw;
import com.fox.Coloring;
import flash.filters.DropShadowFilter;
//import flash.geom.Rectangle;
import mx.utils.Delegate;

class com.fox.HPP {
	private var mode:DistributedValue;
	private var decimals:DistributedValue;
	private var colormode:DistributedValue;
	private var divider:DistributedValue;
	private var divider_custom:DistributedValue;
	private var nametags:DistributedValue;
	private var dropshadows:DistributedValue;
	private var scaling:DistributedValue;
	private var scalingColor:DistributedValue;
	static var Loaded:Boolean;

	public static function main(swfRoot:MovieClip):Void {
		var color = new Coloring();
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
		nametags = DistributedValue.Create("HPP_Nametags");
		dropshadows = DistributedValue.Create("HPP_DropShadow");
		scaling = DistributedValue.Create("HPP_Scaling");
		scalingColor = DistributedValue.Create("HPP_ScalingColor");
	}

	public function Load() {
		Hook();
		colormode.SignalChanged.Connect(settingChanged, this);
		mode.SignalChanged.Connect(settingChanged, this);
		divider.SignalChanged.Connect(settingChanged, this);
		divider_custom.SignalChanged.Connect(settingChanged, this);
		nametags.SignalChanged.Connect(settingChanged, this);
		scaling.SignalChanged.Connect(settingChanged, this);
		scalingColor.SignalChanged.Connect(settingChanged, this);
	}

	public function Unload() {
		colormode.SignalChanged.Disconnect(settingChanged, this);
		mode.SignalChanged.Disconnect(settingChanged, this);
		divider.SignalChanged.Disconnect(settingChanged, this);
		divider_custom.SignalChanged.Disconnect(settingChanged, this);
		nametags.SignalChanged.Disconnect(settingChanged, this);
		scaling.SignalChanged.Disconnect(settingChanged, this);
		scalingColor.SignalChanged.Connect(settingChanged, this);
	}

	public function Activate(config:Archive) {
		if (!Loaded) {
			mode.SetValue(config.FindEntry("Mode", 3));
			decimals.SetValue(config.FindEntry("Decimal", 0));
			colormode.SetValue(config.FindEntry("Color", 1));
			divider.SetValue(config.FindEntry("Dividers", 4));
			divider_custom.SetValue(config.FindEntry("Custom", false));
			nametags.SetValue(config.FindEntry("Nametags", false));
			dropshadows.SetValue(config.FindEntry("DropShadow", true));
			scaling.SetValue(config.FindEntry("Scaling", false));
			scalingColor.SetValue(config.FindEntry("ScalingColor", "#2B0575"));
			Loaded = true;
		}
	}

	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("Mode", mode.GetValue());
		config.AddEntry("Color", colormode.GetValue());
		config.AddEntry("Decimal", decimals.GetValue());
		config.AddEntry("Dividers", divider.GetValue());
		config.AddEntry("Custom", divider_custom.GetValue());
		config.AddEntry("Nametags", nametags.GetValue());
		config.AddEntry("DropShadow", dropshadows.GetValue());
		config.AddEntry("Scaling", scaling.GetValue());
		config.AddEntry("ScalingColor", scalingColor.GetValue());
		return config
	}

	private function settingChanged() {
		if (_global.com.fox.HPPHook) {
			_root.playerinfo.health.HPPLoaded = false;
			_root.playerinfo.health.InitHPP(true);

			_root.targetinfo.health.HPPLoaded = false;
			_root.targetinfo.health.InitHPP(true);

			_root.teamgui.m_DefensiveTarget.health.HPPLoaded = false;
			_root.teamgui.m_DefensiveTarget.health.InitHPP(true);
			for (var i in _root.teamgui.m_CurrentTeam.m_TeamMembers) {
				_root.teamgui.m_CurrentTeam.m_TeamMembers[i].health.HPPLoaded = false;
				_root.teamgui.m_CurrentTeam.m_TeamMembers[i].health.InitHPP(true);
			}
			// untested, but nothing reloadUI can't fix if it doesn't work
			for (var i in _root.teamgui.m_CurrentRaid.m_Teams) {
				for (var y in _root.teamgui.m_CurrentRaid[i].m_TeamMembers) {
					_root.teamgui.m_CurrentRaid[i].m_TeamMembers[y].health.HPPLoaded = false;
					_root.teamgui.m_CurrentRaid[i].m_TeamMembers[y].health.InitHPP(true);
				}
			}
			for (var i in _root.nametagcontroller.m_NametagArray) {
				_root.nametagcontroller.m_NametagArray[i].health.m_ShowText = false;
				_root.nametagcontroller.m_NametagArray[i].health.m_Text._visible = false;
				_root.nametagcontroller.m_NametagArray[i].health.HPPLoaded = false;
				_root.nametagcontroller.m_NametagArray[i].health.InitHPP();
			}
		}
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

		var f:Function = function(force):Void {
			if (!this.HPPLoaded) {
				var text:TextField = this.m_Text;
				if (DistributedValueBase.GetDValue("HPP_DropShadow")) {
					text.filters = [new DropShadowFilter(0, 0, 0x000000, 0.8, 1.5, 1.5, 255, 1, false, false, false)];
				}
				this.isPlayer = this.m_Dynel.GetID().Equal(CharacterBase.GetClientCharID());
				this.colorMode = DistributedValueBase.GetDValue("HPP_ColorMode");
				this.numMode = DistributedValueBase.GetDValue("HPP_Mode");
				this.decimals =  DistributedValueBase.GetDValue("HPP_Decimals");
				this.nametags = DistributedValueBase.GetDValue("HPP_Nametags");
				this.drawHP = !this._parent.m_SelectedForMoveBackground && !this._parent.m_NametagColor; //TeamMember or nametag
				if (!this.m_ShowText && this.nametags) {
					this.m_ShowText = true;
					this.m_Text._visible = true;
					setTimeout(Delegate.create(this, function() {
						this.m_Text._y = -2.30;
					}), 100); // needs delay for some reason
				}
				this.HPPLoaded = true;
				this.Redraw(force);

				/*
				 * Debug
				setInterval(Delegate.create(this, function(){
					this.m_Current = this.m_Current - 100;
					if (this.m_Current < -500) this.m_Current = this.m_Max;
					this.UpdateStatText();
					this.UpdateStatBar();
				}), 200);*/
			}
		}
		f.base = HealthBar.prototype.InitHPP;
		HealthBar.prototype.InitHPP = f;

		// function for initializing graphic container(and clearing it)
		f = function ():Void {
			if (!this.m_Bar.m_Overlay) {
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
			} else{
				/*
				* m_Overlay swaps depths with barrier later, giving it a negative depth
				* movieclips with negative depths cannot be removed
				*/
				if (this.m_Bar.m_Overlay.getDepth() < this.m_Bar.m_Boost.getDepth() && this.m_Bar.m_Boost.getDepth() > 0) {
					this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_Boost);
				} else{
					this.m_Bar.m_Overlay.swapDepths(999);
				}
				this.m_Bar.m_Overlay.removeMovieClip();
				this.m_ThirdShield.m_Overlay.removeMovieClip();
			}
			//scaling hp bar
			//this.m_ThirdShield._x = 0;
			var scalingoverlay:MovieClip = this.m_ThirdShield.createEmptyMovieClip("m_Overlay", this.m_ThirdShield.getNextHighestDepth());
			scalingoverlay._x = this.m_Bar._x + this.m_Bar._width / this.m_Bar._xscale * 100 - this.m_ThirdShield._x;
			Draw.DrawRectangle(scalingoverlay, 0, 0, 1, this.m_Bar.m_ArtworkEnemy._height, Coloring.HexToInt(DistributedValueBase.GetDValue("HPP_ScalingColor")), 75);
			scalingoverlay._width = 0;
			//base
			var m_Overlay = this.m_Bar.createEmptyMovieClip("m_Overlay", this.m_Bar.getNextHighestDepth());
			//Store info for sizing
			m_Overlay._y = this.m_Bar.m_ArtworkEnemy._y - 2;
			m_Overlay.y = this.m_Bar.m_ArtworkEnemy._y;
			m_Overlay.x = this.m_Bar.m_ArtworkEnemy._x - 1;
			m_Overlay.width = this.m_Bar.m_ArtworkEnemy._width + 1;
			m_Overlay.height = this.m_Bar.m_ArtworkEnemy._height - 1;
			//components
			m_Overlay.createEmptyMovieClip("m_Graphics", m_Overlay.getNextHighestDepth());
			m_Overlay.createEmptyMovieClip("m_Divider", m_Overlay.getNextHighestDepth());
			m_Overlay.createEmptyMovieClip("m_Border", m_Overlay.getNextHighestDepth());
			this.m_Text._x = (this.m_Bar._width - this.m_Text._width) * 0.5;
			this.UpdateBaseHealth();
		}
		HealthBar.prototype.InitContainer = f;

		// Creating dividers
		f = function ():Void {
			var dividers = com.GameInterface.DistributedValueBase.GetDValue("HPP_Segments");
			var custom:String = undefined;
			if (this.isPlayer) {
				custom = com.GameInterface.DistributedValueBase.GetDValue("HPP_Segments_Custom");
			}
			if (dividers || custom) {
				Coloring.DrawDivider(this.m_Bar.m_Overlay.m_Divider, dividers, custom);
				// this would allow using segments on nametags/group window
				//MovieClip(this.m_Bar.m_Overlay.m_Divider).scale9Grid = new Rectangle(this.m_Bar.m_Overlay.m_Divider._x, this.m_Bar.m_Overlay.m_Divider._y, this.m_Bar.m_Overlay.m_Divider._width, this.m_Bar.m_Overlay.m_Divider._height);
			}
			Coloring.DrawBox(this.m_Bar.m_Overlay.m_Border, this.m_Bar.m_ArtworkFriend);
		}
		HealthBar.prototype.DrawDividers = f;

		// Redrawing graphics, called when changing settings
		f = function (force):Void {
			if (force || !this.m_Bar.m_Overlay) {
				if (this.drawHP) {
					this.isPlayer = this.m_Dynel.GetID().Equal(CharacterBase.GetClientCharID());
					this.InitContainer();
					this.DrawHealthBar();
					this.DrawDividers();
				}
				this.UpdateStatText();
				this.HideBars();
			}
		}
		HealthBar.prototype.Redraw = f;

		// Drawing graphics
		f = function ():Void {
			if (this.m_Bar.m_Overlay.getDepth() > this.m_Bar.m_Boost.getDepth()) {
				this.m_Bar.m_Overlay.swapDepths(this.m_Bar.m_Boost);
			}
			if (this.colorMode == 2) {
				var color = Coloring.GetColor(1);
				Coloring.DrawSolid(this.m_Bar.m_Overlay.m_Graphics, color);
			} else if (this.colorMode == 3) {
				Coloring.DrawGradient(this.m_Bar.m_Overlay.m_Graphics);
			}
			this.UpdateStatBar();
		}
		HealthBar.prototype.DrawHealthBar = f;

		f = function ():Void {
			arguments.callee.base.apply(this, arguments);
			if (!this.HPPLoaded) {
				this.InitHPP();
			}
			this.HideBars();
			this.UpdateBaseHealth();
		}
		f.base = HealthBar.prototype.SetDynel;
		HealthBar.prototype.SetDynel = f;

		f = function ():Void {
			this.baseHealth = 0;
			if (this.isPlayer && this.drawHP) {
				clearInterval(this.baseHealthInterval);
				this.baseHealthInterval = setInterval(Delegate.create(this, this.GetBaseHealth), 1000);
				this.GetBaseHealth();
			}
		}
		HealthBar.prototype.UpdateBaseHealth = f;

		f = function ():Void {
			for (var i in this.m_Dynel.m_BuffList) {
				var buff:BuffData = this.m_Dynel.m_BuffList[i];
				switch (buff.m_BuffId) {
					case 9256664: // pulverize
					case 9464966: // raging
					case 9469096: // blazing
					case 9464975: // all eyes on me
					case 9269422: // Veil of deformity
					case 7512032: // equal footing
						return;
				}
			}
			var modifier = this.GetHealthModifiers();
			var tankTriangle = this.m_Dynel.GetStat(2000765) / 100;
			this.baseHealth = this.m_Max - Math.ceil(0.5 + tankTriangle * this.m_Dynel.GetStat(2000763, 2) * 2.8562) - modifier;
			clearInterval(this.baseHealthInterval);
		}
		HealthBar.prototype.GetBaseHealth = f;

		f = function() {
			var modifier = 0;
			if (this.m_Dynel.m_BuffList[9271325]) modifier += 1500; // Pure anima
			if (this.m_Dynel.m_BuffList[9271317]) modifier += 1000; // distilled anima
			if (this.m_Dynel.m_BuffList[9271316]) modifier += 1000; // distilled anima

			var agentPassives = [
				AgentSystem.GetPassiveInSlot(0),
				AgentSystem.GetPassiveInSlot(1),
				AgentSystem.GetPassiveInSlot(2)
			];
			for (var i in agentPassives) {
				switch (agentPassives[i]) {
					case 9394871:
					case 9394876:
					case 9394880:
					case 9463143:
					case 9394879:
					case 9454471:
					case 9394872:
					case 9394881:
					case 9394885:
					case 9394884:
					case 9393956:
					case 9393957:
					case 9393958:
					case 9393955:
					case 9393959:
					case 9453206:
						modifier += 490;
						break;
					case 9395011:
					case 9395016:
					case 9393954:
					case 9394886:
					case 9395012:
					case 9395002:
					case 9394887:
					case 9394967:
					case 9395003:
					case 9394968:
					case 9394969:
						modifier += 980;
						break;
				}
			}
			return modifier;
		}
		HealthBar.prototype.GetHealthModifiers = f;

		f = function ():Void {
			var scope = this;
			Tweener.removeTweens(scope.m_Bar);
			Tweener.removeTweens(scope.m_ThirdShield.m_Overlay);
			if (this.m_Dynel.m_BuffList[7512032]) {
				// Equal footing, abort
				scope.m_Bar._xscale = 100;
				scope.m_ThirdShield.m_Overlay._width = 0;
				return;
			}
			var healthRatio = this.m_Dynel.GetStat(2000765) / 100;
			var baseHealth = this.baseHealth;
			baseHealth += this.GetHealthModifiers();
			var unbuffedHP = baseHealth + Math.ceil(0.5 + healthRatio * this.m_Dynel.GetStat(2000763, 2) * 2.8562);
			var targetScale = (this.m_Max / unbuffedHP * 100 + 100) / 2;
			var centerText = function() {
				scope.m_Text._x = (scope.m_Bar._width - scope.m_Text._width) * 0.5;
			}
			var orgWidth = scope.m_Bar._width / scope.m_Bar._xscale * 100;
			var targetWidth = orgWidth * targetScale / 100;

			Tweener.addTween(scope.m_Bar, {_xscale:targetScale, time:2, onUpdate:centerText});
			Tweener.addTween(scope.m_ThirdShield.m_Overlay, {_width:targetWidth-orgWidth, time:2});

		}
		HealthBar.prototype.UpdateBarScale = f;

		f = function() {
			arguments.callee.base.apply(this, arguments);
			if (!this.drawHP ||
				!this.isPlayer ||
				!this.baseHealth ||
				!DistributedValueBase.GetDValue("HPP_Scaling")) return;
			setTimeout(Delegate.create(this, this.UpdateBarScale), 50); // small delay for buffs to properly update
		}
		f.base = HealthBar.prototype.SetMax;
		HealthBar.prototype.SetMax = f;

		f = function() {
			if (this.drawHP) {
				if (this.colorMode == 2 || this.colorMode == 3) {
					this.m_Bar.m_MeterEnemy._alpha = 0;
					this.m_Bar.m_MeterFriend._alpha = 0;
				} else {
					if (this.isPlayer) {
						this.m_Bar.m_MeterFriend._alpha = 100;
					} else {
						this.m_Bar.m_MeterEnemy._alpha = 100;
					}
				}
			}
		}
		HealthBar.prototype.HideBars = f;

		// Extend update HP text function to display health as percentage
		f = function ():Void {
			if (!this.m_ShowText) {
				return;
			}
			if (this.numMode == 2 || this.numMode == 3) {
				var hp = this.m_Current / this.m_Max;
				if (!hp || hp < 0) hp = 0;
				var multi = Math.pow(10, this.decimals);
				var percentage =  Math.round(hp * multi * 100) / multi;
				if (this.numMode == 2) {
					this.m_Text.htmlText = percentage + " %";
				} else {
					var number = this.m_Current + " / " + this.m_Max;
					this.m_Text.htmlText = number + "    " + percentage + " %";
				}
			} else{
				arguments.callee.base.apply(this, arguments);
			}
		}
		f.base = HealthBar.prototype.UpdateStatText;
		HealthBar.prototype.UpdateStatText = f;

		// Extend update HP bar function to update HP bar color
		// Original function still has to draw the barrier first
		// TODO Aegis?
		f = function (snap:Boolean):Void {
			arguments.callee.base.apply(this, arguments);
			if (this.m_Bar.m_Overlay && (this.colorMode == 2 || this.colorMode == 3)) {
				var hp = this.m_Current / this.m_Max;
				if (!hp || hp < 0) hp = 0;
				if (hp > 100) hp = 100;
				// HP based
				// need to recolor on each update
				if (this.colorMode == 2) {
					var color = Coloring.ColorIndex[hp * 20];
					Coloring.Recolor(this.m_Bar.m_Overlay.m_Graphics, color);
				}
				//gradient only needs clipping mask adjustment
				Coloring.setClippingMask(this.m_Bar.m_Overlay.m_Graphics, hp);
			}
		}
		f.base = HealthBar.prototype.UpdateStatBar;
		HealthBar.prototype.UpdateStatBar = f;
		HealthBar.SetDynel();
	}
}