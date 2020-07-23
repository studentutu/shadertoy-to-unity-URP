using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace UmutBebek.URP.ShaderToy
{
    public class MousePosToShader : MonoBehaviour
    {
        private List<Renderer> _renderers;
        private Vector4 _pos = Vector4.zero;
        private MultiPassShader _multiPassShader;

        void Start()
        {
            _renderers = this.GetComponentsInChildren<Renderer>().ToList();
            _multiPassShader = gameObject.GetComponent<MultiPassShader>();
        }

        // Update is called once per frame
        bool _mouseIsDown = false;
        void Update()
        {

            if (Input.GetMouseButton(0))
            {
                _pos = new Vector4(Input.mousePosition.x, Input.mousePosition.y,
                    _pos.z, _pos.w); //do not change z,w

                if (_mouseIsDown == false)
                {
                    _mouseIsDown = true;
                    _pos.z = _pos.x; //it is the current button down place
                    _pos.w = _pos.y;
                }
            }
            else
            {
                if (_mouseIsDown == true)
                {
                    _mouseIsDown = false;
                    _pos.z = -_pos.z; //it is the last button down place
                    _pos.w = -_pos.w;
                }
            }

            if (_renderers != null && _renderers.Count > 0)
            {
                foreach (var ren in _renderers)
                {
                    ren.sharedMaterial.SetVector("iMouse", _pos);
                }
            }

            if (_multiPassShader != null)
            {
                if (_multiPassShader._m1 != null)
                {
                    //Debug.Log("setting pos for multishader pass m1 material");
                    _multiPassShader._m1.SetVector("iMouse", _pos);
                }
                if (_multiPassShader._m2 != null)
                    _multiPassShader._m2.SetVector("iMouse", _pos);
                if (_multiPassShader._m3 != null)
                    _multiPassShader._m3.SetVector("iMouse", _pos);
                if (_multiPassShader._m4 != null)
                    _multiPassShader._m4.SetVector("iMouse", _pos);
                if (_multiPassShader._m5 != null)
                    _multiPassShader._m5.SetVector("iMouse", _pos);
            }
        }
    }
}