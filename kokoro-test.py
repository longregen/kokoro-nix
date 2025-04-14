import kokoro
model = kokoro.KModel(
  config='/media/audio-alicia-2/models/config.json',
  model = '/media/audio-alicia-2/models/kokoro-v1_0.pth')
pipeline = kokoro.KPipeline(lang_code='a',model=model)
