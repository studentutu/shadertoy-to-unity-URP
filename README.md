[![patreon](https://c5.patreon.com/external/logo/become_a_patron_button.png)](https://www.patreon.com/bePatron?u=38416865)

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G2G81V6UH)

# shadertoy-to-unity-URP
I will convert the hottest shaders from shadertoy to Universal SRP shader. I will try to update often; so watch it and support me for more to come :)

## Licence
As you know shadertoy projects are licenced as
[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.](https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US)
Please look into the each shader code if it has another licence. Otherwise above licence must be considered!

## Just Run It

I have separated the each scenes (and materials). So just open the scene and press play :)

## Usage for simple (none-textured) etc.

Just select the Plane on the sample scene, and change it's material shader (by shadertoy name or shadertoy end of link like 4dXGR4)

![github-large](https://github.com/umutbebek/shadertoy-to-unity-URP/blob/master/ScreenShots/plane.JPG)

![github-large](https://github.com/umutbebek/shadertoy-to-unity-URP/blob/master/ScreenShots/select.JPG)

![github-large](https://github.com/umutbebek/shadertoy-to-unity-URP/blob/master/ScreenShots/happy.jpg)

## Usage for textured

Shaders has slots for texture (channel) inputs. So if shadertoy has a texture (noise etc.) you have to attach the correct texture to correct slot.
As an example https://www.shadertoy.com/view/4dXGR4
This shader has a texture on channel0 like below:

![github-large](https://github.com/umutbebek/shadertoy-to-unity-URP/blob/master/ScreenShots/textureSSample.JPG)

So on our samples, after selecting the correct shader; you have to put the same texture (from "Textures" folder) to channel 0 as below, that is it :)

![github-large](https://github.com/umutbebek/shadertoy-to-unity-URP/blob/master/ScreenShots/texture.JPG)

## Usage for movies

If shader uses a movie clip, attach the video file (from "Movies" folder) to "Video Player"s "Video Clip" property which is on "Plane" object (and be sure script is enabled); then select the correct channel on the "Material Property" of the script like below:

![github-large](https://github.com/umutbebek/shadertoy-to-unity-URP/blob/master/ScreenShots/video.JPG)

## Mouse events

Mouse events are send to the shaders automatically by the "Mouse Pos to Shader" script. Hold the left mouse button on play mode to see it (if shader has mouse implementation in it).

## Last words

Some shaders even seems more beautiful, but some not (maybe because float operations etc. i do not know). So please do not write me if it does not behave same :) I hope they will become usefull for you to learn shaders and math :)
