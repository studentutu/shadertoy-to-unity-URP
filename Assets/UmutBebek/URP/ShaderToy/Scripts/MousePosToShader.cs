using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace UmutBebek.URP.ShaderToy
{
    [ExecuteAlways]
    public class MousePosToShader : MonoBehaviour
    {
        private Camera _main;
        private List<Renderer> _renderers;

        void Start()
        {
            _main = Camera.main;
            if (_main is null)
                _main = FindObjectsOfType<Camera>().First();

            _renderers = this.GetComponentsInChildren<Renderer>().ToList();
        }

        // Update is called once per frame
        void Update()
        {
            Vector3 pos = Vector3.zero;
            if (Input.GetMouseButton(0))
            {
                pos = Input.mousePosition;
            }

            if (_renderers != null && _renderers.Count > 0)
            {
                foreach (var ren in _renderers)
                {
                    ren.sharedMaterial.SetVector("iMouse", pos);
                }
            }
        }
    }
}