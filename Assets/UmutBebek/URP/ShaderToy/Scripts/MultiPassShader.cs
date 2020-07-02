using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace UmutBebek.URP.ShaderToy
{
    public class MultiPassShader : MonoBehaviour
    {
        public Shader[] Shaders;
        RenderTexture _rt1, _rt2, _rt3, _rt4, _rt5;
        private List<Renderer> _renderers;
        private Material _m1, _m2, _m3, _m4, _m5;

        // Start is called before the first frame update
        void Start()
        {
            int width = Screen.width + Screen.width % 2;
            int height = Screen.height + Screen.height % 2;
            int depth = 32;
            _rt1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
            _rt2 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
            _rt3 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
            _rt4 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
            _rt5 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
            _rt1.useMipMap = true;
            _rt2.useMipMap = true;
            _rt3.useMipMap = true;
            _rt4.useMipMap = true;
            _rt5.useMipMap = true;
            _rt1.autoGenerateMips = true;
            _rt2.autoGenerateMips = true;
            _rt3.autoGenerateMips = true;
            _rt4.autoGenerateMips = true;
            _rt5.autoGenerateMips = true;

            if(Shaders.Length>0)
                _m1 = new Material(Shaders[0]);
            if (Shaders.Length > 1)
                _m2 = new Material(Shaders[1]);
            if (Shaders.Length > 2)
                _m3 = new Material(Shaders[2]);
            if (Shaders.Length > 3)
                _m4 = new Material(Shaders[3]);
            if (Shaders.Length > 4)
                _m5 = new Material(Shaders[4]);

            _renderers = this.GetComponentsInChildren<Renderer>().ToList();
        }

        // Update is called once per frame
        void Update()
        {
            Graphics.Blit(_rt1, _rt2, _m1);
            
            _m2.SetTexture("_Channel0",_rt2);
            Graphics.Blit(_rt2, _rt3, _m2);

            if (_renderers != null && _renderers.Count > 0)
            {
                foreach (var ren in _renderers)
                {
                    ren.sharedMaterial.SetTexture("_Channel0", _rt3);
                }
            }
        }

        void OnDestroy()
        {
            _rt1.Release();
            _rt2.Release();
            _rt3.Release();
            _rt4.Release();
            _rt5.Release();
        }
    }
}