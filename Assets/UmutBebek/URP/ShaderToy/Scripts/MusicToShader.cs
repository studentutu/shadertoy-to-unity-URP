using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace UmutBebek.URP.ShaderToy
{
    public class MusicToShader : MonoBehaviour
    {

        public enum MusicMaterialType
        {
            musicV4,
            musicV5
        }

        [Tooltip("Set as '_Channel0','_Channel1' etc. for the correct channel")]
        public string channelName = "_Channel0";

        public MusicMaterialType musicMaterialsType;
        [Range(0.0005f, 0.5f)] public float delay = 0.0166f;
        public float multiplier = 1.0f;

        [HideInInspector]
        [System.NonSerialized]
        public float[] spactrumDataDelay;

        [HideInInspector]
        [System.NonSerialized]
        public Texture2D dataTexture;

        public FilterMode filterMode;

        private List<Renderer> _renderers;

        int numSamples = 512;

        void Start()
        {
            _renderers = this.GetComponentsInChildren<Renderer>().ToList();
            
            dataTexture = new Texture2D(numSamples, 1, TextureFormat.RGBA32, false);
            dataTexture.filterMode = filterMode;
            if (_renderers != null && _renderers.Count > 0)
            {
                foreach (var ren in _renderers)
                {
                    ren.sharedMaterial.SetTexture(channelName, dataTexture);
                }
            }

            spactrumDataDelay = new float[numSamples];
        }

        void Update()
        {
            float[] spectrum = new float[numSamples];
            GetComponent<AudioSource>().GetSpectrumData(spectrum, 0, FFTWindow.BlackmanHarris);

            //for (int i = 1; i < spectrum.Length - 1; i++)
            //{
            //    Debug.DrawLine(new Vector3(i - 1, spectrum[i] + 10, 0), new Vector3(i, spectrum[i + 1] + 10, 0), Color.red);
            //    Debug.DrawLine(new Vector3(i - 1, Mathf.Log(spectrum[i - 1]) + 10, 2), new Vector3(i, Mathf.Log(spectrum[i]) + 10, 2), Color.cyan);
            //    Debug.DrawLine(new Vector3(Mathf.Log(i - 1), spectrum[i - 1] - 10, 1), new Vector3(Mathf.Log(i), spectrum[i] - 10, 1), Color.green);
            //    Debug.DrawLine(new Vector3(Mathf.Log(i - 1), Mathf.Log(spectrum[i - 1]), 3), new Vector3(Mathf.Log(i), Mathf.Log(spectrum[i]), 3), Color.blue);
            //}

            //for (int i = 0; i < spectrum.Length; i++)
            //{
            //    dataTexture.SetPixel(i, 0, new Color(spectrum[i]*255, 0, 0, 0));
            //}
            //dataTexture.Apply();
            for (int j = 0; j < 1; j++)
            {
                int i = 1;
                while (i < numSamples + 1)
                {
                    float newData = (spectrum[i - 1] * 1.0f * multiplier);


                    // apply delay 
                    if (newData > spactrumDataDelay[i - 1])
                    {
                        spactrumDataDelay[i - 1] += (delay * Time.deltaTime);
                        if (spactrumDataDelay[i - 1] > newData)
                        {
                            spactrumDataDelay[i - 1] = newData;
                        }
                    }
                    else
                    {
                        spactrumDataDelay[i - 1] -= (delay * Time.deltaTime);
                        if (spactrumDataDelay[i - 1] < 0f)
                        {
                            spactrumDataDelay[i - 1] = 0f;
                        }
                    }

                    // set texture pixes
                    if (musicMaterialsType == MusicMaterialType.musicV4)
                    {
                        dataTexture.SetPixel(i - 1, 1, new Color((spactrumDataDelay[i - 1] * 255.0f), 0, 0, 0));
                    }
                    else
                    {
                        ShaderUtil.WriteFloatToTexturePixel(spactrumDataDelay[i - 1], ref dataTexture, i - 1, 1);
                    }

                    i++;
                }

                // update texture pixels
                dataTexture.Apply();
            }
        }
    }
}