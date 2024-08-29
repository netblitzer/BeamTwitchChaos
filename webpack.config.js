const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  entry: './src/js/index.js',
  mode: 'development',
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, 'ui/modules/apps/BeamTwitchChaos'),
  },
  module: {
    rules: [
      {
        test: /\.less$/i,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
          },
          {
            loader: "css-loader", // translates CSS into CommonJS
            options: {
              url: {
                filter: (url, resourcePath) => {
                  // resourcePath - path to css file
    
                  // Don't handle `img.png` urls
                  if (url.includes(".png")) {
                    return false;
                  }
                  if (url.includes(".otf") || url.includes(".ttf") || url.includes(".woff")) {
                    return false;
                  }
    
                  return true;
                },
              },
            },
          },
          {
            loader: "less-loader", // compiles Less to CSS
          },
        ],
      },
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
  },
  plugins: [new MiniCssExtractPlugin()],
};