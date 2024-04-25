conda activate qiime2-2017.7

pip install deicode

qiime deicode rpca \
    --i-table table.qza \
    --p-min-feature-count 10 \
    --p-min-sample-count 500 \
    --o-biplot ordination.qza \
    --o-distance-matrix distance.qza

qiime emperor biplot \
    --i-biplot ordination.qza \
    --m-sample-metadata-file sample-metadata.tsv \
    --m-feature-metadata-file taxonomy.qza \
    --o-visualization biplot.qzv \
    --p-number-of-features 8

qiime diversity core-metrics-phylogenetic \
    --i-table table.qza \
    --i-phylogeny tree.qza \
    --p-sampling depth 500 \
    --m-metadata-file /path/to/metadata.txt \
    --o-rarefied-table table_rar500.qza \
    --o-faith-pd-vector faiths_pd.qza \
    --o-observed-features-vector observed_features.qza \
    --o-shannon-vector shannon.qza \
    --o-evenness-vector evenness.qza \
    --o-unweighted-unifrac-distance-matrix unifrac_dist.qza \
    --o-weighted-unifrac-distance-matrix wunifrac_dist.qza \
    --o-jaccard-distance-matrix jaccard_dist.qza \
    --o-bray-curtis-distance-matrix bray_dist.qza \
    --o-unweighted-unifrac-pcoa-results unifrac_pcoa.qza \
    --o-weighted-unifrac-pcoa-results wunifrac_pcoa.qza \
    --o-jaccard-pcoa-results jaccard_pcoa.qza \
    --o-bray-curtis-pcoa-results bray_pcoa.qza \
    --o-unweighted-unifrac-emperor unifrac_pcoa.qzv \
    --o-weighted-unifrac-emperor wunifrac_pcoa.qzv \
    --o-jaccard-emperor jaccard_pcoa.qzv \
    --o-bray-curtis-emperor bray_pcoa.qzv \
